<#
.DESCRIPTION
  Checks a file for any changes froom a baseline and displays the
  change in the alerts area.

AUTHOR
Ben0xA

.PARAMETER filename
  The file path to the file to monitor.

.PARAMETER baselinefile
  The file path to the baseline file.

.NOTES
  psfilename=filename,psfilename=baselinefile
#>

Param(
    [Parameter(Mandatory=$true,Position=1)]
    [string]$filename,

    [Parameter(Mandatory=$true,Position=2)]
    [string]$baselinefile
)

#Start your code here.
$baseline = ""
if(test-path $baselinefile) {
    $PSStatus.Update("Getting baseline contents, please wait...")
    $baseline = Get-Content $baselinefile
}
if(test-path $filename) {
    $PSStatus.Update("Getting current contents of the file, please wait...")
    if($baseline -eq "") {
        if($baselinefile -ne "") {
            Get-Content $filename | Out-File $baselinefile    
        }
        $PSAlert.Add("Baseline file created.", 0)
    }
    else {
        $PSStatus.Update("Getting updates, please wait...")
        $curcontent = Get-Content $filename
        $diff = Compare-Object $baseline $curcontent
        $curcontent | Out-File $baselinefile
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
}