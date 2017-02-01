function Invoke-AzureRestApi {
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName="ByTenant", Mandatory=$true, Position=1)][switch]$TenantLevel,
        [Parameter(ParameterSetName="BySubscription", Mandatory=$false, Position=1)]$ResourceGroupName,
        [Parameter(ParameterSetName="ByTenant", Mandatory=$true, Position=2)][Parameter(ParameterSetName="BySubscription", Mandatory=$true, Position=2)]$ResourceType,
        [Parameter(ParameterSetName="ByTenant", Mandatory=$true, Position=3)][Parameter(ParameterSetName="BySubscription", Mandatory=$true, Position=3)]$ResourceName,
        [Parameter(ParameterSetName="ByTenant", Mandatory=$true, Position=4)][Parameter(ParameterSetName="BySubscription", Mandatory=$false, Position=4)]$ExtensionResourceType,
        [Parameter(ParameterSetName="ByTenant", Mandatory=$true, Position=5)][Parameter(ParameterSetName="BySubscription", Mandatory=$false, Position=5)]$ExtensionResourceName,
        [Parameter(ParameterSetName="ByResourceId", Mandatory=$true, Position=1)]$ResourceId,   
        [Parameter(ParameterSetName="FromObject", ValueFromPipeline=$true)]$InputObject,
        $Body = $null,
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
        Write-Verbose "Resource Id: $ResourceId"

        $apiVersion = Find-AzureRmApiVersion -ResourceId $ResourceId -Pre | Select-Object -First 1
        Write-Verbose "API Version: $apiVersion"

        $uri = "{0}{1}?api-version=$apiVersion" -f `
            [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Environment.GetEndpoint([Microsoft.Azure.Commands.Common.Authentication.Models.AzureEnvironment+Endpoint]::ResourceManager),
            $ResourceId
        Write-Verbose "URI: $uri"

        Invoke-WebRequest -Uri $uri -Headers @{
            [Microsoft.WindowsAzure.Commands.Common.ApiConstants]::AuthorizationHeaderName = (Get-AzureRmAccessToken).CreateAuthorizationHeader()
            [Microsoft.WindowsAzure.Commands.Common.ApiConstants]::VersionHeaderName = [Microsoft.WindowsAzure.Commands.Common.ApiConstants]::VersionHeaderContentLatest
        } -Method $Method -Body ($Body | ConvertTo-Json -Compress)  -UseBasicParsing | % Content
    }
}