Param ( 
    [Parameter(Mandatory=$true)] [string]$Category,
    [Parameter(Mandatory=$true)] [string]$Tag, 
    [Parameter(Mandatory=$true)] [string]$SnapshotAction
)

<#
This script will take or remove snapshots from groups of machines with the same tag. It can be useful in scenarios where you will
be doing updates to a large number of machines in a single motion and want to quickly snapshot or remove a snapshot.

Before using in your environment you will need to update two items in this script:

    1. Provide the name of your vCenter in the $vCenter variable
    2. Updatethe variables that define the Category and tags that this script can be used for by updating the following variables:
        $SupportedCategories
        $SupportedTags

Notes:

Snapshots will be provided a specific name to avoid confusion with other snapshots as well as to easily remove the correct snapshot.  
This name will start with "VMSM-" and end with the category/tag used.  For example - snapshots taken for the category Patching and Dev tag will be called:

    VMSM-Patching/Dev

Usage:
To take a snapshot for VMs tagged as Dev in the Patching category
    vm-snapshot-manager.ps1 -Category Patching -Tag Dev -SnapshotAction Create

To delete a snapshot for VMs tagged as Dev in the Patching category
    vm-snapshot-manager.ps1 -Category Patching -Tag Dev -SnapshotAction Delete

Disclaimer:  This script was obtained from https://github.com/cybersylum
  * You are free to use or modify this code for your own purposes.
  * No warranty or support for this code is provided or implied.  
  * Use this at your own risk.  
  * Testing is highly recommended.
#>



##
## Define Environment Variables
##
## Specific to environment - edit before running
$vCenter = "vcsa.cybersylum.com"
#safeguard to ensure only certain categories/tags can be used - update to match your environment
$SupportedCategories = @("Patching")
$SupportedTags = @("Dev","UAT","Prod") # Dev UAT Production

#do not modify
$SupportedSnapshotActions = @("Create","Delete")

# Rate Limiting controls to avoid overloading the vCenter server or storage.  Adjust this to what your environment needs
# $RateLimit is # of snapshots to perform before pausing for $RatePause seconds
$RateLimit=20 
$RatePause=15 #in seconds

$DateStamp=Get-Date -format "yyyyMMdd"
$TimeStamp=Get-Date -format "hhmmss"
$RunLog = "VM-Patching-Snapshot-Manager-$DateStamp-$TimeStamp.log"

##
## Function declarations
##
function Write-Log  {

    param (
        $LogFile,
        $LogMessage    
    )

    # complex strings may require () around message paramter 
    # Write-Log $RunLog ("Read " + $NetworkData.count + " records from $ImportFile. 1st Row is expected to be Column Names as defined in script.")

    $LogMessage | out-file -FilePath $LogFile -Append
}

##
## Main Script
##

#Validate Command Line Args
if ($SupportedCategories.contains($Category) -ne $true) {
    Write-host "Category '$Category' not supported. process aborted."  
    Write-Log $RunLog ("Category $Category not supported")
    exit
}

if ($SupportedTags.contains($Tag) -ne $true) {
    Write-host "Tag '$Tag' not supported. process aborted." 
    Write-Log $RunLog ("Tag '$Tag' not supported. process aborted.")
    exit
}

if ($SupportedSnapshotActions.contains($SnapshotAction) -ne $true) {
    Write-host "Snapshot Action '$SnapshotAction' not supported. process aborted." 
    Write-Log $RunLog ("Snapshot Action '$SnapshotAction' not supported. process aborted.")
    exit
}



#Setup the full Category/Tag string to search properly
$FullTag = $Category + '/' + $Tag

#Connect to vCenter
write-host "Connecting to vCenter Server - $vCenter..."
$VC=connect-viserver -server $vCenter
if ($VC -eq $null) {
    write-host "Unable to connect to vCenter Server '$vCenter'..."
    Write-Log $RunLog ("Unable to connect to vCenter Server '$vCenter'...")
    exit
}

Write-Host "Searching vCenter for VMs tagged as $FullTag"
Write-Log $RunLog  ("Searching vCenter for VMs tagged as $FullTag")


#validate input
#$vms = Get-VM | Get-TagAssignment | where {$_.Tag -like $FullTag} | Select @{N='VM';E={$_.Entity.Name}}
$vms = Get-VM | Get-TagAssignment | where {$_.Tag -like $FullTag}

if ($vms.count -eq 0) {
    Write-Host "No VMs found..."
    Write-Log $RunLog ("No VMs found tagged as $FullTag")
    exit
}

$RateCounter = 0

Write-Host "Executing Snapshot action - $SnapshotAction on each tagged VM..."

foreach ($ListEntry in $vms) {

    $VM = $ListEntry.Entity

    $SnapName = "VMSM-$FullTag"

    if ($SnapshotAction -eq "Create"){
        Write-Host "    Taking snapshot of $VM"
        Write-Log $RunLog (     "Taking snapshot ($SnapName) of $VM")
        #$snap = New-Snapshot -vm $VM -name $SnapName -confirm:$false -Quiesce:$false -RunAsync:$true
    }

    if ($SnapshotAction -eq "Delete"){
        Write-Host "    Deleting snapshot from $VM"
        Write-Log $RunLog (     "Deleting snapshot ($SnapName) from $VM")
        #$snap = get-snapshot -vm $vm -name $SnapName
        #remove-snapshot -snapshot $snap -confirm:$false -RunAsync:$true
    }

    $RateCounter++

    #Rate Limit to avoid overload
        if ($RateCounter -gt $RateLimit) {
            write-host "Sleeping for $RatePause seconds to avoid overload"
            start-sleep -seconds $RatePause
            $RateCounter = 0
        }

}
 
# Clean up
write-host
Write-Host ("More details available in the log - $RunLog")
Disconnect-viserver -Confirm:$false





