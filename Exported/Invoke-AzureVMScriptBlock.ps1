function Invoke-AzureVMScriptBlock {
    [CmdletBinding()]
    param(
        $ResourceGroupName,
        $VMName,
        [scriptblock]$ScriptBlock,
        [switch]$Force,
        [switch]$PassThru
    )

    if (!$VMName) {
        Get-AzureRmVM -ResourceGroupName $ResourceGroupName -WarningAction Ignore | % {
            Invoke-AzureVMScriptBlock -ResourceGroupName $_.ResourceGroupName -VMName $_.Name -ScriptBlock $ScriptBlock -Force:$Force -PassThru:$PassThru
        }
        return
    }

    $fileName = 'AzureRestCustomScript.ps1'
    $blob = New-AzureBlob -BlobName $fileName
    $blob.SetText($ScriptBlock.ToString())
    $fileUri = $blob.BlobSasUri
    Write-Verbose "FileUri: $fileUri"
    
    $azureProfile = [System.IO.Path]::GetTempFileName()
    Save-AzureRmProfile -Path $azureProfile -Force
    
    $job = Start-Job -Name "ScriptExt-$($ResourceGroupName)-$($VMName)" -ScriptBlock {
            param($ModuleBase, $AzureProfile, $SubscriptionId, $ResourceGroupName, $VMName, $FileUri, $FileName, $Force)
            Import-Module (Join-Path $ModuleBase 'AzureRest.psd1') -Force
            
            Select-AzureRmProfile -Profile $AzureProfile | Out-Null
            Remove-Item -Path $AzureProfile -Force | Out-Null
            Select-AzureRmSubscription  -SubscriptionId $SubscriptionId | Out-Null

            $vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName -WarningAction Ignore
    
            $existingCustomScriptExtension = Invoke-AzureRestApi -ResourceId $vm.Id -Json |
                % Resources | ? { $_.type -eq 'Microsoft.Compute/virtualMachines/extensions' -and $_.properties.publisher -eq 'Microsoft.Compute' -and $_.properties.type -eq 'CustomScriptExtension' } |
                % name
            if ($existingCustomScriptExtension) {
                if ($Force) {
                    Write-Warning "CustomScriptExtension already exists ($existingCustomScriptExtension), removing..."
                    Remove-AzureRmVMCustomScriptExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -Name $ExistingCustomScriptExtension -Force | Write-Verbose
                } else {
                    throw "CustomScriptExtension already exists ($existingCustomScriptExtension), specify -Force to replace it"
                }
            }

            $vmExtensionName = 'CustomScriptExtension'
            Write-Verbose 'Setting CustomScriptExtension...'
            Set-AzureRmVMCustomScriptExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -Name $vmExtensionName -Location $vm.Location -FileUri $FileUri -Run $FileName -SecureExecution -ForceRerun (Get-Date).Ticks |
                Format-List |
                Out-String |
                Write-Verbose

            Write-Verbose 'Getting CustomScriptExtension Statuses...'
            Get-AzureRmVMExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -Name $vmExtensionName -Status | % SubStatuses | ? { -not [string]::IsNullOrWhitespace($_.Message) } | % {
                $message = $_.Message.Replace('\n', "`n")
                if ($_.Code.StartsWith('ComponentStatus/StdOut/')) { $message | Write-Output }
                if ($_.Code.StartsWith('ComponentStatus/StdErr/')) { $message | Write-Error }
            }

            Write-Verbose 'Removing CustomScriptExtension...'
            Remove-AzureRmVMCustomScriptExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -Name $vmExtensionName -Force | Write-Verbose
    } -ArgumentList @($ExecutionContext.SessionState.Module.ModuleBase, $azureProfile, (Get-AzureRmContext).Subscription.SubscriptionId, $ResourceGroupName, $VMName, $fileUri, $fileName, $Force)

    if ($PassThru) { $job }
    else { $job | Receive-Job -AutoRemoveJob -Wait }
}
