param([int]$Port = 8765)

$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskWebRoot = Join-Path $taskRoot 'build\web'

if (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue) {
    Write-Output "A porta $Port está em uso. Se o protótipo já estiver aberto, acesse http://127.0.0.1:$Port. Para outra instância, use -Port 8766."
    return
}

if (-not (Test-Path -LiteralPath (Join-Path $taskWebRoot 'index.html'))) {
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Flutter não foi encontrado no PATH.' }
    Push-Location -LiteralPath $taskRoot
    try {
        flutter build web --release --no-web-resources-cdn
        if ($LASTEXITCODE -ne 0) { throw 'A compilação web falhou.' }
    } finally { Pop-Location }
}

if (-not (Get-Command python -ErrorAction SilentlyContinue)) { throw 'Python não foi encontrado no PATH.' }
Write-Output "Calculadora: http://127.0.0.1:$Port"
Write-Output 'Código de demonstração: 31415926 seguido de =. Ctrl+C encerra o servidor.'
python -m http.server $Port --bind 127.0.0.1 --directory $taskWebRoot
