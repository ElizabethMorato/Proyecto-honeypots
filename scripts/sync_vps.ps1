while ($true) {
    scp -i C:\Users\Elizabeth\.ssh\id_rsa_vps `
        root@167.71.8.253:/opt/honeypot/logs/cowrie.json `
        C:\Proyecto-honeypots\logs\cowrie_vps.json
    Write-Host "$(Get-Date) - cowrie_vps.json sincronizado desde VPS"
    Start-Sleep -Seconds 55
}