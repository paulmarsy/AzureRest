function Invoke-AzureVMScriptBlock {
    [CmdletBinding()]
    param(
        $ResourceGroupName,
        $VMName,
        [scriptblock]$ScriptBlock,
        [switch]$Force,
        [switch]$PassThru
    )

    $existingCustomScriptExtension = Invoke-AzureRestApi -ResourceId '/subscriptions/ab25f870-bd70-487d-80d3-76dce74b618d/resourceGroups/AUTOMATIONSTACK77DA/providers/Microsoft.Compute/virtualMachines/test' -Json |
        % Resources | ? { $_.type -eq 'Microsoft.Compute/virtualMachines/extensions' -and $_.properties.publisher -eq 'Microsoft.Compute' -and $_.properties.type -eq 'CustomScriptExtension' } |
        % name
    if ($existingCustomScriptExtension) {
        if ($Force) {
            Write-Warning "CustomScriptExtension already exists ($existingCustomScriptExtension), removing..."
        } else {
            throw "CustomScriptExtension already exists ($existingCustomScriptExtension), specify -Force to replace it"
        }
    }

    $fileName = 'AzureRestCustomScript.ps1'
    $fileUri = Upload-AzureTemporaryFile -FileName $fileName -Value $ScriptBlock.ToString()
    Write-Verbose "FileUri: $fileUri"
    
    $azureProfile = [System.IO.Path]::GetTempFileName()
    Save-AzureRmProfile -Path $azureProfile -Force
    
    $job = Start-Job -Name "CustomScriptExtension-$($ResourceGroupName)-$($VMName)" -ScriptBlock {
            param($AzureProfile, $SubscriptionId, $ResourceGroupName, $VMName, $FileUri, $FileName, $ExistingCustomScriptExtension)
            Select-AzureRmProfile -Profile $AzureProfile | Out-Null
            Remove-Item -Path $AzureProfile -Force | Out-Null
            Select-AzureRmSubscription  -SubscriptionId $SubscriptionId | Out-Null

            if ($ExistingCustomScriptExtension) {
                Write-Verbose "Removing existing CustomScriptExtension $ExistingCustomScriptExtension..."
                Remove-AzureRmVMCustomScriptExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -Name $ExistingCustomScriptExtension -Force | Write-Verbose
            }

            $vmExtensionName = 'CustomScriptExtensionme'
            $vmLocation = Get-AzureRmVM  -ResourceGroupName $ResourceGroupName -Name $VMName -WarningAction Ignore | % Location

            Write-Verbose 'Setting CustomScriptExtension...'
            Set-AzureRmVMCustomScriptExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -Name $vmExtensionName -Location $vmLocation -FileUri $FileUri -Run $FileName -SecureExecution -ForceRerun (Get-Date).Ticks |
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
    } -ArgumentList @($azureProfile, (Get-AzureRmContext).Subscription.SubscriptionId, $ResourceGroupName, $VMName, $fileUri, $fileName, $existingCustomScriptExtension)

    if ($PassThru) { $job }
    else { $job | Receive-Job -AutoRemoveJob -Wait }
}