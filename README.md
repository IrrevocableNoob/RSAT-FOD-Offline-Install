# RSAT-FOD-Offline-Install
Enterprise solution to install RSAT Offline without needing access to windows update


Like many companies, we were struggling to deploy RSAT tools on Windows 11. We had it working fine, modifying two registry entries and running the standard script to reach out to Windows Update for the packages, provided separately in case this works in your environment.

It stopped working a couple months ago because of changes to the way our users authenticate against the firewall for external traffic. Rather than spending a lot of time on that angle for this relatively unique deployment, I elected to work towards offline availability via the features on demand ISO.

There are many pages that discuss how this can be done, however all that I could find are geared towards extracting the features and injecting them into a wim, which was not our usage and not what I wanted to do. Some refer to DISM, some refer to Get-WindowsCapability and Add-WindowsCapabilty; which really are effectively the same thing.

I worked it out, and in the absence of other reference material online, decided to share with you what I did to make it work. For reference, we use SCCM/MECM 2309 and Windows 11 22H3 as of today. All these instructions assume that you are running en-US language and amd64 versions, just modify as necessary.  I’ve provided scripts that do all the heavy lifting.

Steps presented below:
1.	Download Optional Features ISO and extract contents.
2.	Filter contents to needed files and export list of RSAT apps
3.	Install RSAT tools offline via powershell
4.	(Optional) Deploy via SCCM/Intune
5.	Troubleshooting


1. First, we need to obtain the “Language and Optional Features for Windows 11, version 22H2” iso, note that the version will change but the steps should stay the same. To get this, visit my.visualstudio.com, click “downloads”, click “windows 11”, and scroll down—or just search. Download the iso. It winds up around 7 gigs, eww. I believe you can also get it from VLSC, but that’s not where I got it.

Many online instructions will tell you to mount this iso---which you certainly can, I personally prefer to extract with 7-zip or similar app. You’ll wind up with 2 folders, “LanguageAndOptionalFeatures” and “Windows Preinstallation Environment”. Obviously, you need the former.


2. Inside this folder are all the cab files for all FOD package, plus a few index cabs, as well as a metadata subfolder. As of my doing this project, it’s 3,216 files.

In my initial testing I used powershell get-childitem to filter out just the amd64 en-US language cab files and copy them to a new extract folder however this missed the base installer cabs as well as a few utility cabs that must be present for the installs to work, such as “FoDMetadata_Client.cab", and  "Downlevel-NLS-Sorting-Versions-Server-FoD-Package~31bf3856ad364e35~amd64~~.cab" . 


Additionally, this brought over a LOT of cab files for NON-RSAT applications. These may be useful to you, but this document does not cover the installation of those features, and the cleanup is super messy if you’re trying to avoid storing unnecessary files, so I made a more elegant search and find routine to select only the RSAT-related cab files. You can see that in the included script at the bottom.
Additionally, we need files from the “metadata” subfolder. You need en-US files, as well everything not-language specific, and they need to wind up in a “metadata” folder beneath your cabs. For example, c:\temp\extract\metadata


If you’re doing this manually, you’ll want to confirm that it sees all the right apps, like so:
Get-WindowsCapability -Name RSAT* -Online -Source "C:\temp\extract" | Select-Object -Property Name 


From here, delete the cab entries that don’t match your list if you ONLY want RSAT. Be sure to preserve the Downlevel and FoDMetadata cabs.


Because I’m a nice guy, here are the RSAT apps:
Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
Rsat.AzureStack.HCI.Management.Tools~~~~0.0.1.0
Rsat.BitLocker.Recovery.Tools~~~~0.0.1.0
Rsat.CertificateServices.Tools~~~~0.0.1.0
Rsat.DHCP.Tools~~~~0.0.1.0
Rsat.Dns.Tools~~~~0.0.1.0
Rsat.FailoverCluster.Management.Tools~~~~0.0.1.0
Rsat.FileServices.Tools~~~~0.0.1.0
Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0
Rsat.IPAM.Client.Tools~~~~0.0.1.0
Rsat.LLDP.Tools~~~~0.0.1.0
Rsat.NetworkController.Tools~~~~0.0.1.0
Rsat.NetworkLoadBalancing.Tools~~~~0.0.1.0
Rsat.RemoteAccess.Management.Tools~~~~0.0.1.0
Rsat.RemoteDesktop.Services.Tools~~~~0.0.1.0
Rsat.ServerManager.Tools~~~~0.0.1.0
Rsat.StorageMigrationService.Management.Tools~~~~0.0.1.0
Rsat.StorageReplica.Tools~~~~0.0.1.0
Rsat.SystemInsights.Management.Tools~~~~0.0.1.0
Rsat.VolumeActivation.Tools~~~~0.0.1.0
Rsat.WSUS.Tools~~~~0.0.1.0

Great, we’re most of the way there. Once you’ve narrowed down the apps to only the ones you want (plus the downlevel and FoDMetadata cabs!), put them in a repository somewhere---your SCCM server, a network share, a manual copy to a pc you want to install apps on, whatever.

3. For reasons I do not understand, the Add-WindowsCapability cmdlet, even when supplied with the -Source parameter, will STILL try to dial out to Windows Update or your local WSUS server or whatever you have defined in GPO. There’s another parameter, “-LimitAccess” that you must also use to limit it to your source directory. This parameter is missing from most of the script examples you can find online, including ones presented by Microsoft. You must also use Get-WindowsCapability first and then pipe those results to Add-WindowsCapability. 

If you just need this bit, reference “Windows 11 RSAT FOD Install.ps1”. If you want to install something specific, like only ADUC, change the filter like this:
$RSAT_FoD = Get-WindowsCapability –Online | Where-Object Name -like 'RSAT.ActiveDirectory*'
(Or whatever RSAT app(s) you want from above)

4. I personally prefer to use PSADT for as many deployments as possible, the script below “Windows 11 RSAT FOD Install.ps1” has comments to help you integrate it smoothly into PSADT. For detection method, mine just checks for several of the RSAT exe’s or msc’s, for example:
![image](https://github.com/user-attachments/assets/615c773a-13c2-4bf8-b55a-1b227e6a5da3)

 

Other files include dsac.exe, bitlockerdeviceencryption.exe, dnsmgmt.msc, dhcpmgmt.mst.


5. Troubleshooting:
Access Denied errors:
You forgot the -LimitAccess parameter on the Add-WindowsCapability. Oops.

Cannot Find Source Files error in Powershell:
You’re missing one or more cabs (or xml.cab). If you can’t run it down or can’t be bothered, just include *all* the metadata files from the iso. There are a lot of them but it’s only 1.14 Mb.

Please see the following scripts:
RSAT Smart Cab Extract.ps1
Windows 11 RSAT FOD Offline Install.ps1
