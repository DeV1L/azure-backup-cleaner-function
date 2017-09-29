$StorageAccountName = "arkadiumcombackups"
$BlobContainers = "staging","live"
$KeepDays = "180"

#Get access token
function Get-AccessToken 
{
$ApiVersion = "2017-09-01"
$ResourceURI = "https://management.azure.com/"
$TokenAuthURI = $env:MSI_ENDPOINT + "?resource=$ResourceURI&api-version=$ApiVersion"
$TokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret"="$env:MSI_SECRET"} -Uri $TokenAuthURI
$AccessToken = $TokenResponse.access_token
}

#Get storage account key
function Get-StorageAccountKey 
{
Param(
    [string] $Subscription,
    [string] $ResourceGroup,
    [string] $StorageAccount,
    [string] $AccessToken
)
    $Uri = $resourceURI + "subscriptions/$Subscription/resourceGroups/$ResourceGroup/providers/Microsoft.Storage/storageAccounts/$StorageAccount/listKeys/?api-version=2016-12-01"
    $keysResponse = Invoke-RestMethod -Method Post -Headers @{Authorization="Bearer $AccessToken"} -Uri $Uri
    $key = $keysResponse.keys[0].value
}

#Get subfolders
function Delete-Backups 
{
Param(
    [string] $StorageAccountName,
    [string] $StorageAccountKey,
    $Container
)
    $ContextSrc = New-AzureStorageContext $StorageAccountName -StorageAccountKey $StorageAccountKey
    foreach ($_ in $Container) 
        {
        Get-AzureStorageBlob -Context $ContextSrc -Container $_ | Where-Object {$_.LastModified -LT (get-date).AddDays(-$KeepDays)} | Remove-AzureStorageBlob -WhatIf -Verbose
        }
}

#Auth
Get-AccessToken 
$StorageAccountKey = Get-StorageAccountKey -Subscription $env:BackupSubsciption -ResourceGroup $env:BackupResourceGroup -StorageAccount $StorageAccountNameSrc -AccessToken $AccessToken

#Delete backups
Delete-Backups -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey -Container $BlobContainers