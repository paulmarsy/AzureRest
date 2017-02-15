function Upload-AzureTemporaryFile {
    param($FileName, $Value)

    $containerSas = [uri]::new((Invoke-AzureRestApi -Uri 'https://mscompute2.iaas.ext.azure.com/api/Compute/VmExtensions/GetTemporarySas/' -Json))
    $blobContainer = [Microsoft.WindowsAzure.Storage.Blob.CloudBlobContainer]::new($containerSas)
    $blob = $blobContainer.GetBlockBlobReference($FileName)
    $blob.UploadText($Value)
    
    $blob.Uri.AbsoluteUri + $containerSas.Query
}