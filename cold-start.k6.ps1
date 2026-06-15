$urlJit = "https://t3k2lm7eam6baloghit5rtn75i0uejob.lambda-url.us-east-2.on.aws/health"
$urlAot = "https://577xcjudhfbomovavixzxv4cgu0rcdyb.lambda-url.us-east-2.on.aws/health"

Write - Host "Iniciando coleta de Cold Starts..."

    for ($i = 1; $i -le 10; $i++) {
    Write-Host "`n--- Iteracao $i - $(Get-Date) ---"
    
    # Chama o JIT
    $timeJit = Measure-Command { Invoke-RestMethod -Uri $urlJit -Method Get }
    Write-Host "JIT respondeu em: $($timeJit.TotalMilliseconds) ms"
    
    # Chama o AOT
    $timeAot = Measure-Command { Invoke-RestMethod -Uri $urlAot -Method Get }
    Write-Host "AOT respondeu em: $($timeAot.TotalMilliseconds) ms"
    
    if ($i -lt 10) {
        Write-Host "Aguardando 65 minutos para o desprovisionamento da AWS..."
        Start-Sleep -Seconds 3900 
    }
}