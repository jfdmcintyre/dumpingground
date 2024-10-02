$inputTarFile = "C:\_WSL2\wsl-vpnkit.tar.gz"
$outputTarGzFile = "C:\_WSL2\wsl-vpnkit.tar.gz testing.tar.gz"

$compressProcess = Start-Process -FilePath "tar.exe" -ArgumentList @(
    "-czf", 
    $outputTarGzFile, 
    "-C", 
    (Split-Path -Parent $inputTarFile), 
    (Split-Path -Leaf $inputTarFile)
)

if ($compressProcess.ExitCode -eq 0) {
    Write-Host "Compression successful: $outputTarGzFile"
} else {
    Write-Host "Compression failed. Exit code: $($compressProcess.ExitCode)"
}