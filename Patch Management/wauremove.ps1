<#
.DESCRIPTION
Windows Automatic Update Remover
Written by Ben0xA

.PARAMETER kbs
Comma separated values of KB numbers.

.PARAMETER outputFile
The output file to save results. This will override showintab.

.PARAMETER computer
Specifies a single computer to scan.

.PARAMETER showintab
Specifies whether to show the results in a PoshSec Framework Tab.

.NOTES
  pshosts=storedhosts
#>

Param(
	[Parameter(Mandatory=$true,Position=1)]
	[string]$kbs,
	
	[Parameter(Mandatory=$false,Position=2)]
	[string]$outputFile,
	
	[Parameter(Mandatory=$false,Position=4)]
	[string]$computer,

	[Parameter(Mandatory=$false,Position=6)]
	[string]$storedhosts
)

Function Remove-KBs($pcname, $kb){
	Invoke-RemoteWmiProcess $pcname "wusa.exe /uninstall /kb:$($kb) /quiet /norestart" -noredirect -nowait
}

Function Get-KBs($pcname){
	$rslt = ""
	$qfe = Get-WmiObject -Class Win32_QuickFixEngineering -Computer $pcname -ErrorVariable myerror -ErrorAction SilentlyContinue
	if($myerror.count -eq 0) {
		foreach($kb in $kbItems){
			$installed = $false
			$kbentry = $qfe | Select-String $kb
			if($kbentry){
                Write-Output("KB $kb found. Attempting to uninstall, please wait...")
				$rmrslt = Remove-KBs $pcname $kb
                $rslt += "$pcname,$kb,Uninstall Sent`r`n"            
			}
            else {
                $rslt += "$pcname,$kb,Not Installed`r`n"
            }
		}
	}
	else{
		$rslt += "$pcname,$kb,RPC_Error`r`n"
	}
	return $rslt
}

Import-Module $PSModRoot\PoshSec
# Begin Program Flow

Write-Output "WAURemove"
Write-Output "Written By: @Ben0xA"
Write-Output "Huge thanks to @mwjcomputing!`r`n"
Write-Output "Looking for KBs $kbs"
if(-not $outputFile){
	Write-Output "Sending output to the screen. Use -outputFile name to save to a file.`r`n"
}
else {
	Write-Output "Will save csv results to $outputFile. Query messages will only appear on the screen.`r`n"
}

$wumaster = "PC Name,KB,Status`r`n"
$kbItems = $kbs.Split(",")
if(-not $computer){
  if($storedhosts) {
    #The storedhosts have been serialized as a string
    #Before we use them we need to deserialize.
    $hosts = $PSHosts.DeserializeHosts($storedhosts)
  }
  else {
    $hosts = $PSHosts.GetHosts()
  }
  
  if(!$hosts) {
    $hosts = Get-PCs    
    foreach($h in $hosts) {
      $pcs += $h.Properties.name
    }
  }
  else {
    foreach($h in $hosts) {
      $pcs += $h.Name
    }
  }
  
  $idx = 0
  $len = $pcs.length
	foreach($pc in $pcs){
    $idx += 1
		$pcname = $pc
		
		if($pcname){
      $PSStatus.Update("Querying $pcname [$idx of $len]")
      if($showintab) {
        $rsp = Get-KBs($pcname)
        if($rsp -and $rsp -ne "") {
          $results += $rsp
        }
      }
			else {
        $wumaster += Get-KBs($pcname) | Out-String
      }
		}	
	}
}
else{
  $PSStatus.Update("Querying $computer, please wait...")
  if($showintab) {
    $rsp = Get-KBs($computer)
    if($rsp -and $rsp -ne "") {
      $results += $rsp
    }    
  }
	else {
    $wumaster += Get-KBs($computer) | Out-String 
  }
}

if(-not $outputFile){
  if($showintab) {
    $PSTab.AddObjectGrid($results, "Windows KB ($kbs) Results")
  }
  else {
    $wumaster | Out-String
  }	
}
else {
	$wumaster| Out-File $outputFile
	Write-Output "Output saved to $outputFile"
}

#End Program