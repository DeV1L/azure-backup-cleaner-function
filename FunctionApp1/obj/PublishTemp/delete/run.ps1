$BackupSubsciption = $env:BackupSubsciption
$BackupResourceGroup = $env:BackupResourceGroup
$StorageAccountName = $env:StorageAccountName
$ResourceURI = "https://management.azure.com/"
$BlobContainers = "staging","live"
$KeepDays = "-8"

#Get access token
function Get-AccessToken 
{
$ApiVersion = "2017-09-01"
$TokenAuthURI = $env:MSI_ENDPOINT + "?resource=$ResourceURI&api-version=$ApiVersion"
$TokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret"="$env:MSI_SECRET"} -Uri $TokenAuthURI
$TokenResponse.access_token
}

#Perform auth
$AccessToken = Get-AccessToken
#Write-Output "DEBUG: AccessToken = $AccessToken"

#Get storage account key
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
        Write-Output "Container: $_"
        $DeletedBlobs = Get-AzureStorageBlob -Context $ContextSrc -Container $_ | Where-Object {$_.LastModified -LT (get-date).AddDays(-$KeepDays)}
        Write-Output "DELETING:" $DeletedBlobs.Name
        $DeletedBlobs | Remove-AzureStorageBlob
        }
}

#Delete backups
$Result = Delete-Backups -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey -Container $BlobContainers

Write-Output $Result
$Result | ConvertTo-Json >> $res