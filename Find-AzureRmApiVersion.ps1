function Find-AzureRmApiVersion {
    [CmdletBinding(DefaultParameterSetName="ByResourceProvider")]
    param(
        [Parameter(ParameterSetName="ByResourceProvider", Mandatory=$true, Position=1)]$ProviderNamespace,   
        [Parameter(ParameterSetName="ByResourceProvider", Mandatory=$true, Position=2)]$ResourceType,   
        [Parameter(ParameterSetName="ByResourceId", Mandatory=$true, Position=1)]$ResourceId,
        [switch]$Pre
    )

    if ($ResourceId) {
        $ProviderNamespace = [Microsoft.Azure.Commands.ResourceManager.Cmdlets.Components.ResourceIdUtility]::GetExtensionProviderNamespace($ResourceId)
        if (!$ProviderNamespace) {
            $ProviderNamespace =  [Microsoft.Azure.Commands.ResourceManager.Cmdlets.Components.ResourceIdUtility]::GetProviderNamespace($ResourceId)
        }
        Write-Verbose "Provider Namespace: $providerNamespace"

        $ResourceType = [Microsoft.Azure.Commands.ResourceManager.Cmdlets.Components.ResourceIdUtility]::GetExtensionResourceType($ResourceId, $false)
        if (!$ResourceType) {
            $ResourceType = [Microsoft.Azure.Commands.ResourceManager.Cmdlets.Components.ResourceIdUtility]::GetResourceType($ResourceId, $false)
        }
        Write-Verbose "Resource Type: $ResourceType"
    }

    (Get-AzureRmResourceProvider -ProviderNamespace $ProviderNamespace -Pre:$Pre | % ResourceTypes | ? ResourceTypeName -eq $ResourceType | % ApiVersions)
}