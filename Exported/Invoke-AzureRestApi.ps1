function Invoke-AzureRestApi {
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = "ByUri", Mandatory, Position = 1)][ValidateNotNullOrEmpty()]$Uri,
        [Parameter(ParameterSetName = "ByResourceId", Mandatory, Position = 1)][ValidateNotNullOrEmpty()]$ResourceId,
        [Parameter(ParameterSetName = "ByResourceId")][switch]$WithoutSubscriptionId,   
        [Parameter(ParameterSetName = "ByResource", Position = 1)][ValidateNotNullOrEmpty()]$ResourceGroupName,
        [Parameter(ParameterSetName = "ByResource", Mandatory, Position = 2)][ValidateNotNullOrEmpty()]$ResourceType,
        [Parameter(ParameterSetName = "ByResource", Mandatory, Position = 3)][ValidateNotNullOrEmpty()]$ResourceName,
        [Parameter(ParameterSetName = "ByResource", Position = 4)][ValidateNotNullOrEmpty()]$ExtensionResourceType,
        [Parameter(ParameterSetName = "ByResource", Position = 5)][ValidateNotNullOrEmpty()]$ExtensionResourceName,
        [Parameter(ParameterSetName = "ByResourceId", Position = 2)][Parameter(ParameterSetName = "ByResource", Position = 6)][ValidateNotNullOrEmpty()]$Action,
        [Parameter(ParameterSetName = "ByResourceId", Position = 3)][Parameter(ParameterSetName = "ByResource", Position = 7)][ValidateNotNullOrEmpty()]$ODataQuery,
        [Parameter(ParameterSetName = "ByResourceId", Position = 4)][Parameter(ParameterSetName = "ByResource", Position = 8)][ValidateNotNullOrEmpty()]$ApiVersion,
        $Body,
        [ValidateSet("GET", "POST", "PUT", "DELETE")]$Method = "GET",
        [switch]$Json,
        [switch]$Raw
    )

    if ($null -eq [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context) {
        throw [System.Management.Automation.PSInvalidOperationException]::new("Run Login-AzureRmAccount to login.")
    }

    if ($PSCmdlet.ParameterSetName -ne 'ByUri') {
        if ($PSCmdlet.ParameterSetName -eq 'ByResource') {
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
        if (!$ApiVersion) {
            $ApiVersion = Find-AzureRmApiVersion -ResourceId $ResourceId -Pre | Select-Object -First 1
        }
        Write-Verbose "API Version: $apiVersion"

        $Uri = Get-AzureRmResourceUri `
                -EndpointUri ([Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Context.Environment.GetEndpoint([Microsoft.Azure.Commands.Common.Authentication.Models.AzureEnvironment+Endpoint]::ResourceManager)) `
                -ResourceId $ResourceId `
                -ApiVersion $apiVersion `
                -Action $Action `
                -OdataQuery $ODataQuery
    }
    Write-Verbose "URI: $Uri"
    Invoke-WebRequest -Uri $Uri -Headers @{
        [Microsoft.WindowsAzure.Commands.Common.ApiConstants]::AuthorizationHeaderName = (Get-AzureRmAccessToken)
        [Microsoft.WindowsAzure.Commands.Common.ApiConstants]::VersionHeaderName = [Microsoft.WindowsAzure.Commands.Common.ApiConstants]::VersionHeaderContentLatest
    }  -Method $Method -Body $Body -UseBasicParsing | % {
        if ($Raw) { $_.RawContent } 
        if ($Json) { $_.Content | ConvertFrom-Json  }
        else { $_.Content }
    }
}