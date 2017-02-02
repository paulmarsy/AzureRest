function Invoke-AzureRestApi {
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName="ByTenant", Mandatory=$true, Position=1)][switch]$TenantLevel,
        [Parameter(ParameterSetName="BySubscription", Mandatory=$false, Position=1)][ValidateNotNullOrEmpty()]$ResourceGroupName,
        [Parameter(ParameterSetName="ByTenant", Mandatory=$true, Position=2)][Parameter(ParameterSetName="BySubscription", Mandatory=$true, Position=2)][ValidateNotNullOrEmpty()]$ResourceType,
        [Parameter(ParameterSetName="ByTenant", Mandatory=$true, Position=3)][Parameter(ParameterSetName="BySubscription", Mandatory=$true, Position=3)][ValidateNotNullOrEmpty()]$ResourceName,
        [Parameter(ParameterSetName="ByTenant", Mandatory=$false, Position=4)][Parameter(ParameterSetName="BySubscription", Mandatory=$false, Position=4)][ValidateNotNullOrEmpty()]$ExtensionResourceType,
        [Parameter(ParameterSetName="ByTenant", Mandatory=$false, Position=5)][Parameter(ParameterSetName="BySubscription", Mandatory=$false, Position=5)][ValidateNotNullOrEmpty()]$ExtensionResourceName,
    [Parameter(ParameterSetName="ByResourceId", Mandatory=$true, Position=1)][ValidateNotNullOrEmpty()]$ResourceId,
    [Parameter(ParameterSetName="ByResourceId", Mandatory=$false)][switch]$WithoutSubscriptionId,   
        [Parameter(ParameterSetName="FromObject", ValueFromPipeline=$true)]$InputObject,
        [ValidateNotNullOrEmpty()]$Action,
        [ValidateNotNullOrEmpty()]$ODataQuery,
        $Body,
        [ValidateSet("GET", "POST", "PUT", "DELETE")]$Method = "GET"
    )
    process {
        if ($null -eq [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context) {
            throw [System.Management.Automation.PSInvalidOperationException]::new("Run Login-AzureRmAccount to login.")
        }

        if ($InputObject) {
            $ResourceId = $InputObject | % Id
        }
        if ([string]::IsNullOrWhiteSpace($ResourceId)) { 
            $ResourceId = [Microsoft.Azure.Commands.ResourceManager.Cmdlets.Components.ResourceIdUtility]::GetResourceId(
                [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Subscription.Id,
                $ResourceGroupName,
                $ResourceType,
                $ResourceName,
                $ExtensionResourceType,
                $ExtensionResourceName)
        } 
        if ($WithoutSubscriptionId) {
            $ResourceId = '/subscriptions/{0}/{1}' -f [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Subscription.Id.Guid, $ResourceId.TrimStart('/')
        }
        Write-Verbose "Resource Id: $ResourceId"

        $apiVersion = Find-AzureRmApiVersion -ResourceId $ResourceId -Pre | Select-Object -First 1
        Write-Verbose "API Version: $apiVersion"

        $uri = Get-AzureRmResourceUri `
                -EndpointUri ([Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Environment.GetEndpoint([Microsoft.Azure.Commands.Common.Authentication.Models.AzureEnvironment+Endpoint]::ResourceManager)) `
                -ResourceId $ResourceId `
                -ApiVersion $apiVersion `
                -Action $Action `
                -OdataQuery $ODataQuery
        Write-Verbose "URI: $uri"

        Invoke-WebRequest -Uri $uri -Headers @{
            [Microsoft.WindowsAzure.Commands.Common.ApiConstants]::AuthorizationHeaderName = (Get-AzureRmAccessToken).CreateAuthorizationHeader()
            [Microsoft.WindowsAzure.Commands.Common.ApiConstants]::VersionHeaderName = [Microsoft.WindowsAzure.Commands.Common.ApiConstants]::VersionHeaderContentLatest
        } -ContentType 'application/json' -Method $Method -Body ($Body | ConvertTo-Json -Compress)  -UseBasicParsing | % Content | ConvertFrom-Json
    }
}