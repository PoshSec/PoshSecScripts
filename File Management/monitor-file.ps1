<#
.DESCRIPTION
  Monitors a file for any changes and displays the change in the
  alerts area.

AUTHOR
Ben0xA

.PARAMETER filename
  The file path to the file to monitor.
  
.NOTES
  psfilename=filename
#>

Param(
    [Parameter(Mandatory=$true,Position=1)]
    [string]$filename
)

#Start your code here.
$baseline = ""
[date]$lastwrite = "01/01/1900 00:00AM"
[boolean]$monitor = $True;

$PSStatus.Update("Getting current contents of the file, please wait...")
if(test-path $filename) {
    $baseline = Get-Content $filename
    $PSStatus.Update("Pausing for 2 seconds")
    Start-Sleep -s 2
    do {
        $fil = Get-ChildItem $filename
        if($fil.LastWriteTime -gt $lastwrite) {
            $lastwrite = $fil.LastWriteTime
            $PSStatus.Update("Getting updates, please wait...")
            $curcontent = Get-Content $filename
            $diff = Compare-Object $baseline $curcontent
            $baseline = Get-Content $filename
            if($diff) {
                foreach($line in $diff) {
                    [int]$alertlevel = 0
                    if($line -notlike "*INFORMATIONAL*") {
                        if($line -like "*ERROR*") {
                            $alertlevel = 1
                        }
                        elseif($line -like "*WARNING*") {
                            $alertlevel = 2
                        }
                        elseif($line -like "*SEVERE*") {
                            $alertlevel = 3
                        }
                        elseif($line -like "*CRITICAL*") {
                            $alertlevel = 4
                        }
                        $PSAlert.Add($line.InputObject, $alertlevel)    
                    }                    
                }
            }
        }
        else {
            $PSStatus.Update("Nothing to update.")
        }
        $PSStatus.Update("Pausing for 2 seconds")
        Start-Sleep -s 2
    } while ($monitor)
}