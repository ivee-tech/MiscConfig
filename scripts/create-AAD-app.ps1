<#
.SYNOPSIS
	Create an Azure AD App Registration
	
.DESCRIPTION
	Create an Azure AD App Registration with HomePage, ReplyURLs and a Key valid for 1 year.
    It also creates a service principal for this application and assigns Key Vault permissions via an access policy.
    Requires the existing Key Vault resource group and name. 
	 
.EXAMPLE

	C:\PS> ./create-AAD-app.ps1
#>

$appName = "app" + $(Get-Random)
$appURI = "https://" + $appName + ".azurewebsites.net"
$appHomePageUrl = "https://" + $appName + ".azurewebsites.net"
$appReplyURLs = $appURI # @($appURI, $appHomePageURL, "https://localhost:12345")

$rgName = "[Resource Group name]"
$keyVaultName = "[KeyVault name]"

if(!($myApp = Get-AzureADApplication -Filter "DisplayName eq '$($appName)'"  -ErrorAction SilentlyContinue))
{
	$Guid = New-Guid
	$startDate = Get-Date
	
	$PasswordCredential 				= New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordCredential
	$PasswordCredential.StartDate 		= $startDate
	$PasswordCredential.EndDate 		= $startDate.AddYears(1)
	$PasswordCredential.KeyId 			= $Guid
	$PasswordCredential.Value 			= ([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($Guid))))+"="

	$myApp = New-AzureADApplication -DisplayName $appName -IdentifierUris $appURI -Homepage $appHomePageUrl -ReplyUrls $appReplyURLs -PasswordCredentials $PasswordCredential

    $principal = New-AzureADServicePrincipal -AppId $myApp.AppId

    Set-AzureRmKeyVaultAccessPolicy -VaultName $keyVaultName -ResourceGroupName $rgName -ObjectId $principal.ObjectId -PermissionsToSecrets get

	$AppDetailsOutput = "Application Details for the $AADApplicationName application:
=========================================================
Application Name: 	$appName
Application Id:   	$($myApp.AppId)
Secret Key:       	$($PasswordCredential.Value)
"
	Write-Host
	Write-Host $AppDetailsOutput
}
else
{
	Write-Host
	Write-Host -f Yellow Azure AD Application $appName already exists.
}

Write-Host
Write-Host -f Green "Finished"
Write-Host



