## This script is called from the UserData section of the ADOEC2Windows.yaml CloudFormation template to install the ADO Agent
start-transcript "c:\temp\ADO_Agent_install.txt"
## Update python
python -m pip install --upgrade pip
write-host 'upgraded pip'
python -m pip install aws-sam-cli
write-host 'installed aws-sam-cli'
python -m pip install boto3
write-host 'installed boto3'
git config --system core.longpaths true

## Create Local Service Account and install ADO Build Agent folders
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# write-host 'getting ado token and ado service from ssm parameterstore'
# $Token = (Get-SSMParameterValue -Name 'ADOToken' -WithDecryption $True).Parameters[0].Value | ConvertTo-SecureString -asPlainText -Force
# $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($token)
# $ADOToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
# $Service = (Get-SSMParameterValue -Name 'ADOservicePW' -WithDecryption $True).Parameters[0].Value | ConvertTo-SecureString -asPlainText -Force
# $BSTR2 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Service) 
# $ADOservice = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR2)
write-host 'creating local ado service account'
New-LocalUser 'ADOservice' -FullName 'ADOservice' -Description 'Local ADO User Account' -password $Service
Add-LocalGroupMember -Group 'Administrators' -Member 'ADOservice'
write-host 'get Ec2 instanceid for agentname variable'
write-host 'downloading agent zip for installation'
Copy-S3Object -BucketName "ado-buildserver/M1Tools" -Key "vsts-agent-win-x64-2.185.1.zip" -LocalFolder "c:\temp\M1Tools" -Region $region
$zip = $shell.Namespace("C:\temp\M1Tools\vsts-agent-win-x64-2.185.1.zip")
write-host 'Extract vsts agent zip into 2 ado agent folders'
$shell = New-Object -ComObject Shell.Application
$items = $zip.items()
$shell.Namespace("$Destination1").CopyHere($items, 1556)
$shell = New-Object -ComObject Shell.Application
$items = $zip.items()
$shell.Namespace("$Destination2").CopyHere($items, 1556)
$shell = New-Object -ComObject Shell.Application
write-host 'create 2 ado agent directories'
$Destination1 = "C:\ADOAgent1"
$Destination2 = "C:\ADOAgent2"
$Agent1 = "ADOAgent1"
$Agent2 = "ADOAgent2"

## Manual installation due to Private pool
## Install aws config file in ADOservice user directory
write-host 'add AWS default config file to ADO agent user account'
# New-Item -Path "C:\Users\ADOservice" -Name ".aws" -ItemType "directory"
Copy-S3Object -BucketName ado-buildserver -Key 'config' -LocalFolder "C:\Users\ADOservice\.aws\" -Region $region
stop-transcript
