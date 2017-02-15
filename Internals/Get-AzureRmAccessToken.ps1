function Get-AzureRmAccessToken {
    if ($null -eq [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context) {
        throw [System.Management.Automation.PSInvalidOperationException]::new("Run Login-AzureRmAccount to login.")
    }
    
    $authority = (@([Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Environment.GetEndpoint([Microsoft.Azure.Commands.Common.Authentication.Models.AzureEnvironment+Endpoint]::ActiveDirectory),
                    [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Tenant.Id.Guid) -join '')

    $authContext = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new($authority, [Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache]::DefaultShared)

    $authContext.AcquireToken([Microsoft.Azure.Commands.Common.Authentication.Models.AzureEnvironmentConstants]::AzureServiceEndpoint, [Microsoft.Azure.Commands.Common.Authentication.AdalConfiguration]::PowerShellClientId, [Microsoft.Azure.Commands.Common.Authentication.AdalConfiguration]::PowerShellRedirectUri)
}