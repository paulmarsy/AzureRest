function Get-AzureRmAccessToken {
    if ($null -eq [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context) {
        throw [System.Management.Automation.PSInvalidOperationException]::new("Run Login-AzureRmAccount to login.")
    }
    
  [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new(
        (@([Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Environment.GetEndpoint([Microsoft.Azure.Commands.Common.Authentication.Models.AzureEnvironment+Endpoint]::ActiveDirectory),
            [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Tenant.Id.Guid) -join ''),
            [Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache]::DefaultShared).AcquireToken(
                [Microsoft.Azure.Commands.Common.Authentication.Models.AzureEnvironmentConstants]::AzureServiceEndpoint,
                [Microsoft.Azure.Commands.Common.Authentication.AdalConfiguration]::PowerShellClientId,
                [Microsoft.Azure.Commands.Common.Authentication.AdalConfiguration]::PowerShellRedirectUri)
}