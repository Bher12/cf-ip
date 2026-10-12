# cfnb notification wrapper: run main.py, then push result to Telegram
$ErrorActionPreference = 'Continue'
$root = 'C:\cfnb'
$cfg = $null
try { $cfg = Get-Content (Join-Path $root 'config.json') -Raw -Encoding UTF8 | ConvertFrom-Json } catch { }

$startTime = Get-Date
$proc = Start-Process -FilePath 'C:\Program Files\Python312\python.exe' `
    -ArgumentList ('"' + (Join-Path $root 'main.py') + '"') `
    -WorkingDirectory $root -NoNewWindow -Wait -PassThru
$exit = $proc.ExitCode
$endTime = Get-Date

$lines = @()
try { $lines = Get-Content (Join-Path $root 'ip.txt') -EA Stop | Where-Object { $_.Trim() -ne '' } } catch { }
$cnt = $lines.Count
$top = 'n/a'
if ($cnt -gt 0) { $top = $lines[0] }
$elapsed = [int]($endTime - $startTime).TotalSeconds

if ($exit -eq 0 -and $cnt -gt 0) {
    $text = "[cfnb] 优选完成 " + $cnt + " 条" + [char]10 + "最快: " + $top + [char]10 +
        "耗时 " + $elapsed + "s | " + $startTime.ToString('MM-dd HH:mm')
} else {
    $text = "[cfnb] 运行失败 exit=" + $exit + " 节点数=" + $cnt + " | " + $startTime.ToString('MM-dd HH:mm')
}

$enabled = $false; $token = ''; $chat = ''
try {
    $enabled = [bool]$cfg.TELEGRAM_ENABLED
    $token = [string]$cfg.TELEGRAM_BOT_TOKEN
    $chat = [string]$cfg.TELEGRAM_CHAT_ID
} catch { }

if ($enabled -and $token -ne '' -and $token -notlike 'YOUR_*' -and $chat -ne '' -and $chat -notlike 'YOUR_*') {
    $body = '{"chat_id":"' + $chat + '","text":"' + ($text -replace '"', "'") + '"}'
    $uri = 'https://api.telegram.org/bot' + $token + '/sendMessage'
    $proxyUrl = ''
    try { $proxyUrl = [string]$cfg.TELEGRAM_PROXY } catch { }
    $sent = $false
    if ($proxyUrl -ne '' -and $proxyUrl -notlike 'YOUR_*') {
        try {
            Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType 'application/json' -Proxy $proxyUrl -TimeoutSec 15 | Out-Null
            $sent = $true
        } catch { }
    }
    if (-not $sent) {
        try {
            Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 15 | Out-Null
        } catch { }
    }
}
exit $exit
