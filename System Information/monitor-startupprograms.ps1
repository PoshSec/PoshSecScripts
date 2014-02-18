<#
.DESCRIPTION
  Monitors all of the applications that are set to starup in the \Run
  folder of the registry and compares them to a previous baseline.

AUTHOR
Ben0xA

.PARAMETER baselinefile
  The file to use to store the baseline.

.PARAMETER storedhosts
  This is for storing hosts from the framework for scheduling.

.NOTES
  pshosts=storedhosts
  psfilename=baselinefile
#>

Param(	
	[Parameter(Mandatory=$false,Position=1)]
	[string]$baselinefile,
  
  [Parameter(Mandatory=$false,Position=2)]
	[string]$storedhosts
)
#Required to use PoshSec functions
Import-Module $PSModRoot\PoshSec

#Start your code here.
$progs = @()

if($storedhosts) {
  #The storedhosts have been serialized as a string
  #Before we use them we need to deserialize.
  $hosts = $PSHosts.DeserializeHosts($storedhosts)
}
else {
  $hosts = $PSHosts.GetHosts()
}

if($hosts) {
  foreach($h in $hosts) {
    $PSStatus.Update("Querying $($h.Name), please wait...")
    $progs +=  Get-RemoteRegistryValue $h.Name 3 "Software\Microsoft\Windows\CurrentVersion\Run\"
    $progs +=  Get-RemoteRegistryValue $h.Name 3 "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run\"
  }
  
  if($progs) {
    if(Test-Path $baselinefile) {
      $baseline = Import-CliXml $baselinefile
      $results = Compare-Object $baseline $progs
      if($results) {
        foreach($rslt in $results) {
          switch($rslt.SideIndicator)
          {
            "<=" { $PSAlert.Add("Program Removed: $($rslt.InputObject)", 2)}
            "=>" { $PSAlert.Add("Program Added: $($rslt.InputObject)", 2)}
          }          
        }
        #save the new progs as the new baseline
        $progs | Export-CliXml $baselinefile
      }
    }
    else {
      $progs | Export-CliXml $baselinefile
      Write-Output "Baseline file created."
    }
  }
  else {
    Write-Output "Unable to find any startup programs"
  }
}
else {
  Write-Output "Please select the hosts in the Systems tab to scan."
}

#End Script