<#
This script is provided without warranties, guarantees, referees, or Applebee's. Don't run code you haven't investigated. You will need to be an admin to do these things, almost certainly. This script will overwrite the contents of the defined folders. Comment out Step 9 if you don't want to check back and make sure you got all the apps.

When complete it will spit out a list of available apps to $destinationFolder\rsatapps.txt
#>

# Step 1: Define your source and destination folders. I highly suggest doing this locally in testing and not to a network share.
$sourceFolder = "C:\SCCMApps\RSAT Offline\mul_windows_11_languages_and_optional_features_x64_dvd_dbe9044b\LanguagesAndOptionalFeatures"  # Replace with actual path to your CAB files
$destinationFolder = "C:\SCCMApps\smartcabtest"  # Destination for RSAT-related CAB files


# Step 2: Get RSAT Capability names. Don't edit this, this is getting the current "master list" from Microsoft. If you can't reach out to the internet AT ALL, edit the variable to look like this: $rsatCapabilities = Get-WindowsCapability -Name RSAT* -Online -Source $SourceFolder | Select-Object -ExpandProperty Name

$rsatCapabilities = Get-WindowsCapability -Name RSAT* -Online | Select-Object -ExpandProperty Name


###No need to edit past here####

# Ensure the destination folder exists
New-Item -ItemType Directory -Path $destinationFolder -Force

# Step 3: Process the RSAT capability names to match against the CAB files
foreach ($capability in $rsatCapabilities) {
    # Example: Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
    # Split on `.` and take the main part of the feature name, e.g., 'ActiveDirectory'
    $featureParts = $capability -split "\."
    $featureName = $featureParts[1]  # Extract 'ActiveDirectory', 'DNS', 'DHCP', etc.

    # Step 4: Find corresponding CAB files (base and en-US versions) in the folder
    # Match both base and language-specific files (en-US)
    $cabFiles = Get-ChildItem -Path $sourceFolder -Filter "*$featureName*" | 
                Where-Object { $_.Name -like "*amd64~~.cab" -or $_.Name -like "*amd64~en-us~.cab" }

    # Step 5: Copy the matched CAB files to the destination
    foreach ($cab in $cabFiles) {
        $destinationPath = Join-Path -Path $destinationFolder -ChildPath $cab.Name
        Copy-Item -Path $cab.FullName -Destination $destinationPath -Force
        Write-Host "Copied: $($cab.Name)"
    }
}
###You're a cheeky bugger, aren't you?#####
# Step 6: Manually copy specific files
$additionalFiles = @(
    "FoDMetadata_Client.cab",
    "Downlevel-NLS-Sorting-Versions-Server-FoD-Package~31bf3856ad364e35~amd64~~.cab"
)

foreach ($file in $additionalFiles) {
    $filePath = Join-Path -Path $sourcePath -ChildPath $file
    if (Test-Path -Path $filePath) {
        Copy-Item -Path $filePath -Destination $destinationPath
    } else {
        Write-Host "File $file not found in $sourcePath"
    }
}

$metadataSourcePath = Join-Path -Path $sourceFolder -ChildPath "metadata"  # Source \metadata folder
$metadataDestinationPath = Join-Path -Path $destinationFolder -ChildPath "metadata"  # Destination \metadata folder

# Step 7: Ensure the \metadata destination directory exists
New-Item -ItemType Directory -Path $metadataDestinationPath -Force

# Step 8: Copy items from the \metadata subfolder matching the second filter
Get-ChildItem -Path $metadataSourcePath -Recurse | 
    Where-Object { $_.Name -like "*en-US*" -or $_.Name -like "DesktopTargetCompDB_*" } |
    Copy-Item -Destination $metadataDestinationPath


#Step 9: Check Available RSAT apps
Get-WindowsCapability -Name RSAT* -Online -Source "$destinationFolder" |
    Select-Object -ExpandProperty Name |
    Out-File -FilePath "$destinationFolder\rsatapps.txt" -Encoding ASCII


Write-Host "RSAT CAB file extraction completed!"
