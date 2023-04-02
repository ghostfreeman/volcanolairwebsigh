echo "Building site..."
hugo
echo "Uploading to DreamHost"
scp -rp public/* dh_cpk8sq@alfalfa.dreamhost.com:volcanolair.co
Write-Host "Complete."