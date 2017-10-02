# Function App to remove old backups from Azure Storage

### Setup
1) Deploy function 
2) Place variables at the "Platform features" -> "Application settings" -> "Add new setting":
* BackupSubsciption - ID of Azure Subscription where the Storage Account is
* BackupResourceGroup - name of Resource Group where the Storage Account is
* StorageAccountName - name of Storage Account where the backups is
