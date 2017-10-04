﻿$BackupSubsciption = $env:BackupSubsciption
$BackupResourceGroup = $env:BackupResourceGroup
$StorageAccountName = $env:StorageAccountName
$BlobContainers = "staging","live"
$KeepDays = "-180"

#Email settings
$SendTo = "y.savchenko@arkadium.com"
$Subj = "TEST"
$SMTPserver = "smtp.gmail.com"
$SMTPPort = "587"

#Function: send result to email
function Send-Result 
{
Param(
	$Body,
    $From,
    $Password
)
	$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $From, $($Password | ConvertTo-SecureString -AsPlainText -Force) 
	Send-MailMessage –From $From –To $SendTo –Subject $Subj –Body $Body -SmtpServer $SMTPserver -Credential $Credentials -UseSsl -Port $SMTPPort
}

#Function: get access token
function Get-AccessToken 
{
	$ResourceURI = "https://management.azure.com/"
    $ApiVersion = "2017-09-01"
    $TokenAuthURI = $env:MSI_ENDPOINT + "?resource=$ResourceURI&api-version=$ApiVersion"
    $TokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret"="$env:MSI_SECRET"} -Uri $TokenAuthURI
    $TokenResponse.access_token
}

#Perform auth
$AccessToken = Get-AccessToken
Write-Output "DEBUG: AccessToken = $AccessToken"

#Function: get storage account key
function Get-StorageAccountKey 
{
Param(
    [string] $Subscription,
    [string] $ResourceGroup,
    [string] $StorageAccount,
    [string] $AccessToken
)
    $Uri = $ResourceURI + "subscriptions/$Subscription/resourceGroups/$ResourceGroup/providers/Microsoft.Storage/storageAccounts/$StorageAccount/listKeys/?api-version=2016-12-01"
    $keysResponse = Invoke-RestMethod -Method Post -Headers @{Authorization="Bearer $AccessToken"} -Uri $Uri
    $keysResponse.keys[0].value
}
#Write-Output "DEBUG: BackupSubsciption = $BackupSubsciption "
#Write-Output "DEBUG: BackupResourceGroup = $BackupResourceGroup "
#Write-Output "DEBUG: StorageAccountName = $StorageAccountName "
$StorageAccountKey = Get-StorageAccountKey -Subscription $BackupSubsciption -ResourceGroup $env:BackupResourceGroup -StorageAccount $StorageAccountName -AccessToken $AccessToken
#Write-Output "DEBUG: StorageAccountKey = $StorageAccountKey"


#Function: get Key Vault access token
function Get-AccessTokenKeyVault 
{
	$ResourceURI = "https://vault.azure.net"
	$ApiVersion = "2017-09-01"
	$TokenAuthURI = $env:MSI_ENDPOINT + "?resource=$ResourceURI&api-version=$ApiVersion"
	$TokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret"="$env:MSI_SECRET"} -Uri $TokenAuthURI
	$TokenResponse.access_token
}

#Function: get Key Vault secret
function Get-KeyVaultSecret
{
Param(
    [string] $AccessTokenKeyVault,
    [string] $SecretName
)
    $ResourceURI = "https://arkadium.vault.azure.net"
    $Uri = $ResourceURI + "/secrets/$SecretName/?api-version=2016-10-01"
    $keysResponse = Invoke-RestMethod -Method Get -Headers @{Authorization="Bearer $AccessTokenKeyVault"} -Uri $Uri
    $keysResponse
}

#Function: get subfolders
function Test-Backups 
{
Param(
    [string] $StorageAccountName,
    [string] $StorageAccountKey,
    $Container
)
    $ContextSrc = New-AzureStorageContext $StorageAccountName -StorageAccountKey $StorageAccountKey
    foreach ($_ in $Container) 
        {
        Write-Output "Container: $_"
        $DeletedBlobs = Get-AzureStorageBlob -Context $ContextSrc -Container $_ | Where-Object {$_.LastModified -LT (get-date).AddDays(-$KeepDays)}
        Write-Output "DELETING:" $DeletedBlobs.Name
        }
}



#Obtain secrets
$AccessTokenKeyVault = Get-AccessTokenKeyVault
Write-Output "DEBUG: AccessTokenKeyVault = $AccessTokenKeyVault"

$From = (Get-KeyVaultSecret -AccessToken $AccessTokenKeyVault -SecretName arkadium-sender-login).value
$Password = (Get-KeyVaultSecret -AccessToken $AccessTokenKeyVault -SecretName arkadium-sender-password).value
Write-Output "DEBUG: From = $From , Password = $Password"

#Delete backups
$Result = Test-Backups -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey -Container $BlobContainers

Write-Output $Result
$Result | ConvertTo-Json >> $res
[string]$Body = Get-Content $res -Raw 
Send-Result  -From $From -Password $Password -Body $Body

