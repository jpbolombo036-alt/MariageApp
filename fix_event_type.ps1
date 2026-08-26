$p = 'C:\Users\Ir John Peter\Downloads\MariageApp-main\lib\features\organisateur\shared\widgets\app_event_cards.dart'
$lines = Get-Content $p
$filtered = $lines | Where-Object {
    $_ -notmatch "import '../../../../src/wedding/wedding_api.dart';" -and
    $_ -notmatch 'String eventTypeLabel\(' -and
    $_ -notmatch 'String eventTypeEmoji\('
}
$filtered | Set-Content $p
Write-Host 'done'
