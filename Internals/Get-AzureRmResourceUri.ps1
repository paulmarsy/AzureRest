function Get-AzureRmResourceUri {
    param($EndpointUri, $ResourceId, $ApiVersion, $Action, $OdataQuery)
        
    $relativeUri = $ResourceId.TrimEnd('/')

    if (!([string]::IsNullOrWhiteSpace($Action))) {
        $relativeUri += '/{0}' -f $Action
    }

    if (!([string]::IsNullOrWhiteSpace($OdataQuery))) { $OdataQuery = "&$OdataQuery" }
    else { $OdataQuery = [string]::Empty }

    $relativeUri += '?api-version={0}{1}' -f $ApiVersion, $OdataQuery

    $relativeUri = ($relativeUri.GetEnumerator() | % { 
        if ([char]::IsWhiteSpace($_)) { '%20' }
        else { $_ }
    }) -join ''

    '{0}{1}' -f $EndpointUri.Trim('/'), $relativeUri 
}