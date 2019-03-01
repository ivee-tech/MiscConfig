<#
.SYNOPSIS
	Set an Azure Key Vault secret
	
.DESCRIPTION
	Set a secret in Azure Key Vault. The default secret name is JwtExample-SigningKey.
    Requires the existing Key Vault resource group and name. 
	 
.EXAMPLE

	C:\PS> ./set-keyvault-secret.ps1
#>

$rgName = "[Resource Group name]"
$keyVaultName = "[KeyVault name]"
$secretName = 'Name'
$key = 'Stewie Griffin'


$secretvalue = ConvertTo-SecureString $key -AsPlainText -Force
$secret = Set-AzureKeyVaultSecret -VaultName $keyVaultName -Name $secretName -SecretValue $secretvalue

# Verify
(Get-AzureKeyVaultSecret -vaultName $keyVaultName -name $secretName).SecretValueText
