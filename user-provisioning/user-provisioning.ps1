# ==========================================
# Criação de Usuário - Microsoft 365
# ==========================================

Import-Module MSOnline

# Conectar
Connect-MsolService

# Dados do usuário
$nome = Read-Host "Nome completo"
$email = Read-Host "Email"
$senha = Read-Host "Senha inicial"

try {
    Write-Host "Criando usuário..." -ForegroundColor Cyan

    New-MsolUser `
        -DisplayName $nome `
        -UserPrincipalName $email `
        -Password $senha `
        -ForceChangePassword $true

    Write-Host "Usuário criado com sucesso!" -ForegroundColor Green
}
catch {
    Write-Host "Erro ao criar usuário:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}
