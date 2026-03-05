$ErrorActionPreference = "Stop"
Set-Location "c:\Users\pedro\x"

$target1 = "local paralelos = { `"combate`", `"treino`", `"silent`", `"player`", `"jogos`" }`nfor _, nome in ipairs(paralelos) do`n    task.spawn(ler, nome)`nend"
$target2 = $target1.Replace("`n", "`r`n")

$uiCode = [System.IO.File]::ReadAllText("c:\Users\pedro\x\UI")
$uiCode = $uiCode.Replace($target1, "-- [[ Loader Removido ]] --")
$uiCode = $uiCode.Replace($target2, "-- [[ Loader Removido ]] --")

$files = @("combate.lua", "jogos.lua", "player.lua", "silent.lua", "treino.lua")

foreach ($file in $files) {
    if (Test-Path $file) {
        $content = [System.IO.File]::ReadAllText("c:\Users\pedro\x\$file")
        $uiCode += "`r`n`r`n-- ===== $file ===== --`r`ntask.spawn(function()`r`n$content`r`nend)`r`n"
        Write-Host "Mesclou $file"
    }
    else {
        Write-Warning "Arquivo $file nao encontrado"
    }
}

[System.IO.File]::WriteAllText("c:\Users\pedro\x\michigun.lua", $uiCode)
Write-Host "Arquivo michigun.lua criado com sucesso com todos os conteudos."

# Limpeza
Remove-Item "merge.ps1" -ErrorAction SilentlyContinue
Remove-Item "merge.py" -ErrorAction SilentlyContinue
