# ================= CONFIG =================
$csvPath = "C:\Temp\Migracao\MATCH_FINAL_OK.csv"
$tempPath = "C:\Temp\MigrationTemp"
$logPath = "C:\Temp\Migracao\log_migracao.csv"

$clientId = "SEU_CLIENT_ID_AQUI"

$batchSize = 1
$startIndex = 0
# ==========================================

if (!(Test-Path $tempPath)) {
    New-Item -ItemType Directory -Path $tempPath
}

$rows = Import-Csv $csvPath
$batch = $rows | Select-Object -Skip $startIndex -First $batchSize

foreach ($row in $batch) {

    Write-Host "`n=====================================" -ForegroundColor Cyan
    Write-Host "MIGRANDO: $($row.NomePasta)" -ForegroundColor Yellow

    $fullUrl = $row.SourceUrl
    $siteUrl = ($fullUrl -split "/Documentos Compartilhados")[0]
    $folderRelative = "Documentos Compartilhados" + ($fullUrl -split "/Documentos Compartilhados")[1]

    try {
        # ORIGEM
        Connect-PnPOnline -Url $siteUrl -ClientId $clientId -Interactive

        $items = Get-PnPFolderItem `
            -FolderSiteRelativeUrl $folderRelative `
            -ItemType File `
            -Recursive

        $downloadedFiles = @()

        foreach ($item in $items) {
            $fileUrl = $item.ServerRelativeUrl
            $fileName = $item.Name

            $relativePath = $fileUrl -replace ".*/Documentos Compartilhados/", ""
            $tempFileName = [guid]::NewGuid().ToString() + "_" + $fileName
            $tempFile = Join-Path $tempPath $tempFileName

            try {
                Get-PnPFile -Url $fileUrl `
                            -Path $tempPath `
                            -FileName $tempFileName `
                            -AsFile `
                            -Force

                $downloadedFiles += [PSCustomObject]@{
                    TempPath = $tempFile
                    RelativePath = $relativePath
                    FileName = $fileName
                }
            }
            catch {
                Write-Host "Erro no download: $fileName" -ForegroundColor Red
            }
        }

        # DESTINO
        Connect-PnPOnline -Url $row.TargetUrl -ClientId $clientId -Interactive

        $library = (Get-PnPList | Where-Object {
            $_.BaseTemplate -eq 101 -and $_.Hidden -eq $false
        } | Select-Object -First 1)

        $libraryRoot = $library.RootFolder.ServerRelativeUrl

        foreach ($file in $downloadedFiles) {

            $relativePath = $file.RelativePath
            $fileName = $file.FileName
            $folderPath = Split-Path $relativePath -Parent
            $tempFile = $file.TempPath

            try {
                $targetFolder = $libraryRoot

                if ($folderPath -ne "") {
                    $targetFolder = "$libraryRoot/$folderPath"

                    $parts = $folderPath -split "/"
                    $currentPath = $libraryRoot

                    foreach ($part in $parts) {
                        $parent = $currentPath
                        $currentPath = "$currentPath/$part"

                        try {
                            Add-PnPFolder -Name $part -Folder $parent -ErrorAction Stop
                        }
                        catch {}
                    }
                }

                Add-PnPFile `
                    -Path $tempFile `
                    -Folder $targetFolder `
                    -NewFileName $fileName

                "$($row.NomePasta),$relativePath,OK" | Out-File -Append $logPath
            }
            catch {
                "$($row.NomePasta),$relativePath,ERRO" | Out-File -Append $logPath
            }

            if (Test-Path $tempFile) {
                Remove-Item $tempFile -Force
            }
        }
    }
    catch {
        Write-Host "Erro geral na pasta: $($row.NomePasta)" -ForegroundColor Red
    }
}

Write-Host "`n=== FINALIZADO ===" -ForegroundColor Green
