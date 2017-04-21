function Get-AzureRmAccessToken {
    if ($null -eq [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context) {
        throw [System.Management.Automation.PSInvalidOperationException]::new("Run Login-AzureRmAccount to login.")
    }   
    $account = [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Account
    $environment = [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Environment
    $tenant = [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Tenant.Id.Guid
    $password = $null
    $promptBehavior = [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never
    $tokenCache = [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.TokenCache
    $resourceId = [Microsoft.Azure.Commands.Common.Authentication.Models.AzureEnvironment+Endpoint]::ActiveDirectory
    $accessToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::AuthenticationFactory.Authenticate($account, $environment, $tenant, $password, $promptBehavior, $tokenCache, $resourceId).AccessToken
    
    [System.Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $accessToken)
}