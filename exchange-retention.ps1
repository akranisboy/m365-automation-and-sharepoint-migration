# ==========================================
# Exchange Online - Retention Policy Script
# ==========================================

# Conectar no Exchange Online
Connect-ExchangeOnline

# Nome da mailbox ou grupo
$mailbox = Read-Host "Digite o e-mail da mailbox"

# Nome da política de retenção
$retentionPolicy = Read-Host "Digite o nome da política de retenção"

try {
    Write-Host "Aplicando política de retenção..." -ForegroundColor Cyan

    Set-Mailbox -Identity $mailbox -RetentionPolicy $retentionPolicy

    Write-Host "Executando Managed Folder Assistant..." -ForegroundColor Yellow

    Start-ManagedFolderAssistant -Identity $mailbox

    Write-Host "Processo concluído com sucesso!" -ForegroundColor Green
}
catch {
    Write-Host "Erro ao aplicar política:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}
