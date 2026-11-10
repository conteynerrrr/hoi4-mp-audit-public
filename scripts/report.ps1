[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$LogPath,
    [string]$OutputPath,
    [Alias('Player')][string]$Sender,
    [ValidateRange(1, 200000)][int]$MaxRows = 10000,
    [switch]$Csv,
    [switch]$ExpandBatches,
    [switch]$IncludeEmptyUnknown,
    [switch]$ExcludeEngineAI,
    [ValidateRange(1, 500)][int]$MovementBurstWindowMs = 50
)
$ErrorActionPreference = 'Stop'
$source = (Resolve-Path -LiteralPath $LogPath).Path
$sourceIsDirectory = Test-Path -LiteralPath $source -PathType Container
if (-not $OutputPath) { $OutputPath = $(if ($sourceIsDirectory) { Join-Path $source 'mp_audit_report' } else { $source }) + $(if ($Csv) { '.csv' } else { '.html' }) }
$output = [IO.Path]::GetFullPath($OutputPath)
if ([string]::Equals($source, $output, [StringComparison]::OrdinalIgnoreCase)) { throw 'Report output must differ from the source log.' }
$rows = [Collections.Generic.Queue[object]]::new()
$status = [Collections.Generic.List[string]]::new()
$malformed = 0
$omittedEmpty = 0
$omittedAI = 0
function Utc-Text([object]$Value) {
    if ($Value -is [DateTime]) { return $Value.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffffffZ") }
    return [string]$Value
}
function Test-EmptyUnknown($e) {
    if ($e.event -ne 'command_execute_enter' -or $e.origin_kind -ne 'unknown' -or $e.execution_context -ne 'unknown' -or
        ($null -ne $e.machine_id -and $e.machine_id -ge 0) -or $e.sender_machine_name -or $e.player_name -or $e.command_identity -or
        $null -ne $e.authenticated_peer_machine_id -or $null -ne $e.object_id -or $null -ne $e.country_id -or $null -ne $e.human_id -or
        $null -ne $e.execution_result -or $e.human_author_verified -or $e.actor_name -or $e.message -or $e.payload_hex) { return $false }
    foreach ($p in $e.parameters.PSObject.Properties) {
        if ($p.Name -notin @('original_id','targeted_asynchronous') -or $p.Value) { return $false }
    }
    return $true
}
function Movement-Key($e) {
    if ($e.command_class -notin @('CMoveCommand','CCancelMovementCommand','CStrategicRedeploymentCommand') -or
        $e.execution_context -ne 'queue_execution' -or $null -eq $e.machine_id -or $e.machine_id -lt 0 -or
        -not $e.command_identity -or $null -eq $e.tick -or -not $e.session_id -or
        $e.origin_kind -in @('engine_ai','replay','mixed_or_ambiguous')) { return $null }
    $values = @($e.schema,$e.session_id,$e.event,$e.command,$e.command_class,$e.machine_id,$e.human_id,$e.country_id,
        $e.sender_machine_name,$e.player_name,$e.sender_id_label,$e.actor_name,$e.actor_source,$e.human_author_verified,
        $e.origin_kind,$e.execution_context,$e.origin_site_rva,$e.authenticated_peer_machine_id,$e.attribution,
        $e.tick,$e.session_counter,$e.execution_result,$e.message,($null -ne $e.object_id),[bool]$e.payload_hex)
    return ConvertTo-Json -InputObject $values -Compress -Depth 5
}
function Decode-Envelope($e) {
    if ($e.event -ne 'command_batch') { return ,$e }
    if ($e.schema -ne 4 -or $e.grouping -ne 'movement_burst' -or $e.click_verified -ne $false -or
        $e.count -lt 2 -or $e.count -gt 128 -or $e.entries.Count -ne $e.count -or $e.base.event -ne 'command_execute_enter') {
        throw 'Invalid movement batch envelope.'
    }
    foreach ($delta in $e.entries) {
        $record = [ordered]@{}
        foreach ($p in $e.base.PSObject.Properties) { $record[$p.Name] = $p.Value }
        foreach ($p in $delta.PSObject.Properties) {
            if ($p.Name -notin @('sequence','utc','utc_filetime','qpc','command_identity','tick','object_id','parameters','payload_hex')) { throw 'Unsupported batch override.' }
            $record[$p.Name] = $p.Value
        }
        [pscustomobject]$record
    }
}
$files = $(if ($sourceIsDirectory) {
    @(Get-ChildItem -LiteralPath $source -File | Where-Object {
        $_.Name -match '^mp_audit_.*\.jsonl(\.gz)?$' -and
        (-not $_.Name.EndsWith('.gz', [StringComparison]::OrdinalIgnoreCase) -or
            -not (Test-Path -LiteralPath $_.FullName.Substring(0, $_.FullName.Length - 3)))
    } | Sort-Object Name)
} else { @(Get-Item -LiteralPath $source) })
if (-not $files.Count) { throw 'No JSONL or JSONL.GZ logs found.' }
# Stream gzip rather than expanding it to disk; bounded tail memory for large sessions.
$tail = [Collections.Generic.Queue[string]]::new()
foreach ($file in $files) {
    $stream = $null; $gzip = $null; $reader = $null
    try {
        $stream = [IO.File]::Open($file.FullName, [IO.FileMode]::Open, [IO.FileAccess]::Read, ([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
        $inputStream = $stream
        if ($file.Name.EndsWith('.gz', [StringComparison]::OrdinalIgnoreCase)) {
            $gzip = [IO.Compression.GZipStream]::new($stream, [IO.Compression.CompressionMode]::Decompress, $true)
            $inputStream = $gzip
        }
        $reader = [IO.StreamReader]::new($inputStream, [Text.UTF8Encoding]::new($false, $true))
        while (($line = $reader.ReadLine()) -ne $null) {
            $tail.Enqueue($line)
            if ($tail.Count -gt $MaxRows) { [void]$tail.Dequeue() }
        }
    } finally {
        if ($reader) { $reader.Dispose() }
        if ($gzip) { $gzip.Dispose() }
        if ($stream) { $stream.Dispose() }
    }
}
foreach ($line in $tail) {
    if (-not $line.Trim()) { continue }
    try { $envelope = $line | ConvertFrom-Json -ErrorAction Stop; $decoded = @(Decode-Envelope $envelope) } catch { $malformed++; continue }
    foreach ($entry in $decoded) {
    if ($entry.event -ne 'command_execute_enter') {
        $status.Add(('{0} {1}: {2}' -f $entry.utc, $entry.event, $entry.message))
        continue
    }
    if ($ExcludeEngineAI -and $entry.origin_kind -eq 'engine_ai') { $omittedAI++; continue }
    if (-not $IncludeEmptyUnknown -and (Test-EmptyUnknown $entry)) { $omittedEmpty++; continue }
    # Schemas 1/2 called this player_name; it was always sender-machine metadata.
    $senderName = $(if ($entry.sender_machine_name) { [string]$entry.sender_machine_name } elseif ($entry.player_name) { [string]$entry.player_name } else { '' })
    $verifiedAuthor = $entry.human_author_verified -eq $true -and $entry.actor_source -eq 'verified_human' -and -not [string]::IsNullOrWhiteSpace([string]$entry.actor_name)
    if ($Sender -and -not [string]::Equals($senderName, $Sender, [StringComparison]::OrdinalIgnoreCase)) { continue }
    $parameters = @()
    $originLabels = @{ engine_ai='ИИ движка'; local_interface='Локальный интерфейс'; network_peer='Принято от сетевого участника'; replay='Повтор / синхронизация'; mixed_or_ambiguous='Неоднозначный источник' }
    $origin = $(if ($originLabels.ContainsKey([string]$entry.origin_kind)) { $originLabels[[string]$entry.origin_kind] } else { 'Не установлен' })
    if ($entry.parameters) { $parameters = @($entry.parameters.PSObject.Properties | ForEach-Object { '{0}={1}' -f $_.Name, $_.Value }) }
    $rows.Enqueue([pscustomobject][ordered]@{
        UTC = Utc-Text $entry.utc
        LastUTC = Utc-Text $entry.utc
        Count = 1
        Grouping = ''
        _LastTicks = 0
        _Record = $entry
        _Members = [Collections.Generic.List[object]]::new()
        Author = $(if ($verifiedAuthor) { [string]$entry.actor_name } else { 'Не установлен' })
        Origin = $origin
        ExecutionContext = [string]$entry.execution_context
        OriginSiteRVA = $entry.origin_site_rva
        SenderMachine = $(if ($senderName) { $senderName } else { '(unknown)' })
        Attribution = $(if ($verifiedAuthor) { 'Человек подтверждён' } else { 'Только отправитель; автор неизвестен' })
        HumanVerified = [bool]$verifiedAuthor
        Machine = $entry.machine_id
        Identity = $entry.command_identity
        Tickstamp = $entry.tick
        Command = $(if ($entry.command) { $entry.command } else { $entry.command_class })
        Class = $entry.command_class
        Parameters = $parameters -join '; '
        Text = $entry.message
    })
    if ($rows.Count -gt $MaxRows) { [void]$rows.Dequeue() }
    }
}
if (-not $ExpandBatches) {
    $grouped = [Collections.Generic.List[object]]::new()
    $previous = $null; $previousKey = $null; $firstTicks = 0
    foreach ($row in $rows) {
        $key = Movement-Key $row._Record
        try { $ticks = [DateTime]::Parse($row.UTC,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::RoundtripKind).ToUniversalTime().Ticks } catch { $key=$null; $ticks=0 }
        if ($previous -and $key -and $key -ceq $previousKey -and $previous.Count -lt 128 -and
            $ticks -ge $previous._LastTicks -and $ticks-$firstTicks -le ([long]$MovementBurstWindowMs*10000) -and
            $row._Record.sequence -gt $previous._Members[$previous._Members.Count-1].sequence) {
            $previous.Count++
            $previous.LastUTC=$row.UTC
            $previous._LastTicks=$ticks
            $previous.Grouping='Серия приказов; один клик не подтверждён'
            $previous.Identity=([string]$previous.Identity)+','+([string]$row.Identity)
            $previous._Members.Add($row._Record)
        } else {
            $row._LastTicks=$ticks
            $row._Members.Add($row._Record)
            $grouped.Add($row); $previous=$row; $previousKey=$key; $firstTicks=$ticks
        }
    }
    $rows=$grouped
}
$columns = @('UTC', 'LastUTC', 'Count', 'Grouping', 'Origin', 'Author', 'SenderMachine', 'Attribution', 'HumanVerified', 'ExecutionContext', 'OriginSiteRVA', 'Machine', 'Identity', 'Tickstamp', 'Command', 'Class', 'Parameters', 'Text')
if ($Csv) {
    $rows | Select-Object -Property $columns | Export-Csv -LiteralPath $output -NoTypeInformation -Encoding UTF8
} else {
    function Escape([object]$Value) { [Net.WebUtility]::HtmlEncode([string]$Value) }
    $html = [Text.StringBuilder]::new()
    [void]$html.AppendLine('<!doctype html><html lang="ru"><meta charset="utf-8"><title>HOI4 MP Audit</title>')
    [void]$html.AppendLine('<style>body{font:14px system-ui;margin:28px;color:#ddd;background:#15191e}h1{font-size:24px}table{border-collapse:collapse;width:100%}td,th{padding:8px;border:1px solid #3a444f;text-align:left;vertical-align:top}th{background:#263240;position:sticky;top:0}tbody tr:nth-child(even){background:#1c232b}p,pre{line-height:1.5}pre{white-space:pre-wrap}input{padding:9px;width:min(600px,90%);margin:12px 0;background:#263240;color:#fff;border:1px solid #667}</style>')
    [void]$html.AppendLine('<h1>HOI4 MP Audit</h1><p><strong>Автор и машина-отправитель — разные сведения.</strong> В колонке «Автор» стоит «Не установлен», пока нет отдельного подтверждения человеческого авторства. Ник машины-отправителя может принадлежать хосту даже для команд ИИ. Старое поле player_name трактуется только как имя машины. По одному такому совпадению нельзя утверждать, что действие сделал указанный человек. Записан вход в метод исполнения команды, а не подтверждение успешного изменения состояния или гриферства.</p>')
    [void]$html.AppendLine(('<p>Файл: {0}<br>Последние строк: до {1}. Записей команд: {2}. Неразобранных строк: {3}.</p>' -f (Escape $source), $MaxRows, $rows.Count, $malformed))
    [void]$html.AppendLine('<p>«Источник»: ИИ движка — наблюдалась отправка через проверенный путь ИИ; локальный интерфейс — проверенный путь назначения авиамиссии; сетевой участник — команда прошла проверку отправителя на хосте. Сетевой источник сам по себе не доказывает ручное действие человека. Остальные пути остаются неизвестными. Старые логи нельзя задним числом разделить на ИИ и человека.</p>')
    [void]$html.AppendLine(('<p>Пустых неизвестных записей скрыто: {0}. Серии объединяются по отправителю, типу, tickstamp и окну до {1} мс, максимум 128 команд. Это не подтверждение одного клика и не число юнитов. UTC — время входа в исполнение. Подробности серии раскрываются в колонке «Команд»; исходные времена и ID сохранены. -ExpandBatches показывает команды отдельно; -IncludeEmptyUnknown возвращает пустые записи.</p>' -f $omittedEmpty,$MovementBurstWindowMs))
    [void]$html.AppendLine(('<p>Записей engine_ai скрыто: {0}. -ExcludeEngineAI исключает только подтверждённый источник ИИ; unknown остаётся неизвестным.</p>' -f $omittedAI))
    [void]$html.AppendLine('<input id="search" placeholder="Поиск: ник, команда, объект…" aria-label="Поиск по журналу"><table><thead><tr>')
    $labels = @{ LastUTC='Последнее исполнение UTC'; Count='Команд'; Grouping='Группировка'; Author='Автор'; Origin='Источник'; ExecutionContext='Контекст исполнения'; OriginSiteRVA='Точка наблюдения RVA'; SenderMachine='Машина-отправитель'; Attribution='Атрибуция'; HumanVerified='Человек подтверждён' }
    foreach ($column in $columns) { $label = $(if ($labels.ContainsKey($column)) { $labels[$column] } else { $column }); [void]$html.Append('<th>' + (Escape $label) + '</th>') }
    [void]$html.AppendLine('</tr></thead><tbody>')
    foreach ($row in $rows) {
        [void]$html.Append('<tr>')
        foreach ($column in $columns) {
            if ($column -eq 'Count' -and $row.Count -gt 1) {
                [void]$html.Append('<td><details><summary>'+(Escape $row.Count)+' команд</summary><pre>')
                foreach ($member in $row._Members) { [void]$html.AppendLine((Escape ($member | ConvertTo-Json -Compress -Depth 8))) }
                [void]$html.Append('</pre></details></td>')
            } else { [void]$html.Append('<td>' + (Escape $row.$column) + '</td>') }
        }
        [void]$html.AppendLine('</tr>')
    }
    [void]$html.AppendLine('</tbody></table><h2>Служебные сообщения в выбранном диапазоне</h2><pre>')
    foreach ($item in $status) { [void]$html.AppendLine((Escape $item)) }
    [void]$html.AppendLine('</pre><script>document.getElementById("search").addEventListener("input",function(){const q=this.value.toLocaleLowerCase();for(const row of document.querySelectorAll("tbody tr")){row.hidden=!row.textContent.toLocaleLowerCase().includes(q)}})</script></html>')
    [IO.File]::WriteAllText($output, $html.ToString(), [Text.UTF8Encoding]::new($false))
}
Write-Output "Created $output"
