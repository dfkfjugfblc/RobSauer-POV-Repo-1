## This script is called from the UserData section of the ADOEC2Windows.yaml CloudFormation template
## Install GetModule for SQLServer, add WIX VSTools and Python version within ADO Agent directory 
write-host ''
start-transcript "c:\temp\Modules.txt"
write-host ''
write-host 'Starting PS GetModules -SQLServer'
write-host ''
write-host ''
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -RequiredVersion 2.8.5.201 -Force -Confirm:$False
write-host ''
write-host 'go to next step PSGallery'
write-host ''
Register-PSRepository -Default -Verbose
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
#Install-Module PowerShellGet -RequiredVersion 2.2.4 -SkipPublisherCheck -Force -Confirm:$False
write-host ''
write-host 'Install SqlServer'
write-host ''
Set-ExecutionPolicy RemoteSigned
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
Install-Module PowerShellGet -RequiredVersion 2.2.4 -SkipPublisherCheck
Find-Module -Name 'SqlServer' | 
Save-Module -Path "C:\temp\"
Install-Module -Name SqlServer -Force -Verbose
#Install-Module -Name SqlServer -RequiredVersion 21.1.18221 -Scope CurrentUser -Force -Confirm:$False -Verbose
write-host ''
write-host ''
write-host 'Finished GetModules'
write-host ''
write-host 'Download 2017/2019 WIX VSTools from TIER0 s3 ado-buildserver bucket'
write-host ''
## Download WIX VSTools folders
write-host ''
write-host ''
Copy-S3Object -BucketName ado-buildserver -KeyPrefix 2017 -LocalFolder "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\MSBuild\Microsoft\" -Region US-West-2
Copy-S3Object -BucketName ado-buildserver -KeyPrefix 2019 -LocalFolder "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Microsoft\" -Region US-West-2
write-host ''
write-host ''
write-host 'Finished downloading s3 2017/2019 WIX VSTools objects'
write-host ''
write-host ''
## Install Python for ADO Agent
$webclient = new-object net.webclient
$instanceid = $webclient.Downloadstring('http://169.254.169.254/latest/meta-data/instance-id')
write-host ''
Write-Host 'Add Python version for ADO Agent'
write-host ''
write-host ''
$pyVersion = (&{python --version})
$fullPath = (Get-Command python.exe).Path
$verArray = $pyVersion.Split(' ')
$verNO = $verArray[1]
$pyPath = Split-Path -Path $fullPath
$ADO_Path = "C:\$instanceid\_work\_tool\Python\$verNO\x64\"
Get-ChildItem -Path $pyPath | Copy-Item -Destination $ADO_Path -Recurse -Force
New-Item -Path C:\$instanceid\_work\_tool\Python\$verNO -Name 'x64.complete' -ItemType 'file' -Force
write-host ''
Write-Host 'Python version 3.8.6 for ADO Agent complete'
write-host ''
Write-Host 'Modules installation complete'
write-host ''
stop-transcript