$StartSec = (Get-Date).Second
echo "Building site..."
hugo
echo "Uploading to DreamHost"
scp -rp public/* dh_cpk8sq@alfalfa.dreamhost.com:volcanolair.co
$EndSec = (Get-Date).Second
Write-Host "Complete. Took $($EndSec - $StartSec) second(s) to complete."