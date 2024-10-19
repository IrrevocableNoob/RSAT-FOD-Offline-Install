<#
This script is provided without warranties, guarantees, referees, or Applebee's. Don't run code you haven't investigated. You will need to be an admin to do these things, almost certainly. This script will overwrite the contents of the defined folders. Comment out Step 9 if you don't want to check back and make sure you got all the apps.
#>

<#The location of all of your cabs. If using PSADT, just set #FoD_Source = $dirFiles and put all cabs in the "Files" folder of your PSADT source folder and the "metadata" folder beneath that. Final structure would be:
AppSourceOnServer
	-Files (all cabs)
		-metadata (contents of whole folder)
#>

$FoD_Source = "C:\temp\extract"

#Grab all available RSAT Features
$RSAT_FoD = Get-WindowsCapability -Name RSAT.* -Online -Source $FoD_Source

#Alternatively if you want something specific like just ADUC, comment out line 4 and use this var instead:
#$RSAT_FoD = Get-WindowsCapability -Name RSAT.ActiveDirectory* -Online -Source $dirFiles

#Install RSAT Tools
Foreach ($RSAT_FoD_Item in $RSAT_FoD)
{
Add-WindowsCapability -Online -Name $RSAT_FoD_Item.name -Source $FoD_Source -LimitAccess
}

