function New-AzureBlob {
    [OutputType([AzureTemporarySasBlob])]
    param([Parameter(Position=1)][ValidateNotNullOrEmpty()][Alias('Name')][string]$BlobName)

    [AzureTemporarySasBlob]::new($BlobName)
}
class AzureTemporarySasBlob {
    AzureTemporarySasBlob([string]$BlobName) {
        $this.ContainerSas = [uri]::new((Invoke-AzureRestApi -Uri 'https://mscompute2.iaas.ext.azure.com/api/Compute/VmExtensions/GetTemporarySas/' -Json))
        $this.CloudBlobContainer = [Microsoft.WindowsAzure.Storage.Blob.CloudBlobContainer]::new($this.ContainerSas)
        if ($BlobName) {
            $this.SetBlobName($BlobName)
        }

        $this | Add-Member ScriptProperty Name { $this.BlobReference.Name }
        $this | Add-Member ScriptProperty Exists { $this.BlobReference.Exists() }
        $this | Add-Member ScriptProperty Length { $this.BlobReference.Properties.Length }
        $this | Add-Member ScriptProperty BlobSasUri { [uri]::new($this.BlobReference.Uri.AbsoluteUri + $this.ContainerSas.Query) }
    }

    hidden [uri]$ContainerSas
    hidden [Microsoft.WindowsAzure.Storage.Blob.CloudBlobContainer]$CloudBlobContainer
    hidden [Microsoft.WindowsAzure.Storage.Blob.CloudBlockBlob]$BlobReference

    [void] SetBlobName([string]$BlobName) { $this.BlobReference = $this.CloudBlobContainer.GetBlockBlobReference($BlobName) }
    
    [string] GetText() { return $this.BlobReference.DownloadText() }
    [void] SetText([string]$Text) { $this.BlobReference.UploadText($Text) }

    [void] DownloadToFile([string]$Path) { $this.BlobReference.DownloadToFile($global:ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path), [System.IO.FileMode]::OpenOrCreate) }
    [void] UploadFromFile([string]$Path) { $this.BlobReference.UploadFromFile($global:ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path), [System.IO.FileMode]::Open) }

    [string] ToString() { return $this.BlobSasUri.AbsoluteUri  }
}