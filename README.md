# Function App to remove old backups from Azure Storage

### Requirements
1) Azure Function App
2) Azure Key Vault
3) Email credantial


### Configuration
**Settings**
Place variables at the `"Platform features" -> "Application settings" -> "Add new setting"`:
* `BackupSubsciption` -  Azure Subscription ID for the Storage Account
* `BackupResourceGroup` - Resource Group for the Storage Account
* `StorageAccountName` - name of the Storage Account where backups is

**Rotation**
Backups rotation period is set in the `run.ps1` at the variable `$KeepDays = "180"`

**Blob containers**
Containers are set in the `run.ps1` at the variable `$BlobContainers = "staging","live"`

**Email settings**
Settings are set in the `run.ps1` at the section `#Email settings`

Username and password are set in the KeyVault. Managed service identity have to be enable.
Read example [here](http://www.trueadmin.ru/2018/05/email-azure-functions-secure-way.html) 
