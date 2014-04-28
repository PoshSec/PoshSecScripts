<#
.DESCRIPTION
  Unregister VGX fix for CVE-2014-1776.
  
  Will run the following command on the selected hosts:
  regsvr32.exe -u \"%CommonProgramFiles%\Microsoft Shared\VGX\vgx.dll"

REQUIRES
  PoshSec Modules: Invoke-RemoteWmiProcess
  Download from here -> https://github.com/PoshSec/PoshSec/tree/master
  
ADVISORIES
https://technet.microsoft.com/library/security/2963983

CVE-2014-1776
KB2963983 

AUTHOR
Ben0xA

.PARAMETER showintab
  Specifies whether to show the results in a PoshSec Framework Tab.

.PARAMETER storedhosts
  This is for storing hosts from the framework for scheduling.

.NOTES
  pshosts=storedhosts
#>

Param(	
	[Parameter(Mandatory=$false,Position=1)]
	[boolean]$showintab=$True,
  
  [Parameter(Mandatory=$false,Position=2)]
	[string]$storedhosts
)
#Required to use PoshSec functions
Import-Module $PSModRoot\PoshSec

if($storedhosts) {
  #The storedhosts have been serialized as a string
  #Before we use them we need to deserialize.
  $hosts = $PSHosts.DeserializeHosts($storedhosts)
}
else {
  $hosts = $PSHosts.GetHosts()
}

$hoststats = @()

if($hosts) {
  foreach($h in $hosts) {
    $PSStatus.Update("Applying Fix to $($h.Name), please wait...")

    $result = $null
    try {
      $result = Invoke-RemoteWmiProcess $h.Name "cmd /c C:\Windows\System32\regsvr32.exe -u -s `"C:\Program Files\Common Files\Microsoft Shared\VGX\vgx.dll`"" -noredirect
    }
    catch {
      $result = $null
    }

    $hoststats += $result
  }
  
  if($hoststats) {
    if($showintab) {
      $PSTab.AddObjectGrid($hoststats, "IE0Day Results")
      Write-Output "IE0Day Results Tab Created."
    }
    else {
      $hoststats | Out-String
    }    
  }
  else {
    Write-Output "Unable to find any hosts."
  }
}
else {
  Write-Output "Please select the hosts in the Systems tab to scan."
}

#End Script