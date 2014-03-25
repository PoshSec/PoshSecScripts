<#
.DESCRIPTION
  Scan for CVE-2014-1761.
  
  Will Query the selected hosts to see if they have Office 2003
  installed. If they do, it will iterate each account to see if
  that account under HKEY_CURRENT_USER has the DWORD of RtfFiles
  set to 1 under
  HKEY_CURRENT_USER\Software\Microsoft\Office\11.0\Word\Security\FileOpenBlock
  
ADVISORIES
https://technet.microsoft.com/en-us/security/advisory/2953095

CVE-2014-1761
KB2953095

NOTES
This is for Office 2003 only. For later versions use GPO or
Plan File Blocking.

See http://technet.microsoft.com/library/cc179230

AUTHOR
Ben0xA

.PARAMETER showintab
  Specifies whether to show the results in a PoshSec Framework Tab.

.PARAMETER storedhosts
  This is for storing hosts from the framework for scheduling.

.PARAMETER applyfix
  Specifies whether to apply the DWORD fix to 1 to block RTF Files.

.NOTES
  pshosts=storedhosts
#>

Param(	
	[Parameter(Mandatory=$false,Position=1)]
	[boolean]$showintab=$True,
  
  [Parameter(Mandatory=$false,Position=2)]
	[string]$storedhosts,
  
  [Parameter(Mandatory=$false,Position=3)]
	[boolean]$applyfix=$false
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
    $PSStatus.Update("Querying $($h.Name), please wait...")
    
    $profiles = $null
    try {
      #checks to see if the box will even respond to a RPC call
      #this will return all Profiles for HKEY_USERS
      $profiles = Get-RemoteRegistryKey $h.Name 3 "Software\Microsoft\Windows NT\CurrentVersion\ProfileList"
    }
    catch {
      $profiles = $null
    }
    
    $keys = @()
    if($profiles) {
      foreach($profile in $profiles) {
        if($profile.Key -like "S-1-5-21*") {
          #attempt to see if they have Word 2003 installed
          $key = Get-RemoteRegistryKey $h.Name 4 "$($profile.Key)\Software\Microsoft\Office\11.0\Word\"
          if($key) {
            $keys += $profile.Key
          }
        }
      }
      if($keys) {
        foreach($key in $keys) {
          #the path to the Key for RtfFiles:DWORD
          $hkpath = "$($key)\Software\Microsoft\Office\11.0\Word\Security\FileOpenBlock\"
          $blockrtfdword = Get-RemoteRegistryValue $h.Name 4 $hkpath
          $hoststat = New-Object PSObject
          $hoststat | Add-Member -MemberType NoteProperty -Name "Computer" -Value $h.Name
          $hoststat | Add-Member -MemberType NoteProperty -Name "Word2003Installed" -Value "True"
          $hoststat | Add-Member -MemberType NoteProperty -Name "Profile" -Value $key
          $blocking = $false
          if($blockrtfdword) {
            if($blockrtfdword.Name -eq "RtfFiles" -and $blockrtfdword.Value -eq 1) {
              #the DWORD exists and is already set to block
              $blocking = $true
            }
          }
          if($blocking) {            
              $hoststat | Add-Member -MemberType NoteProperty -Name "BlockingRTF" -Value "True"
              $hoststat | Add-Member -MemberType NoteProperty -Name "AppliedBlock" -Value ""
          }
          else {
            $hoststat | Add-Member -MemberType NoteProperty -Name "BlockingRTF" -Value "False"
            if($applyfix) {
              $reg = Get-RemoteRegistry $h.Name
              if(!$blockrtfdword) {
                #the DWORD does not exist. Create it and the path
                $rslt = $reg.CreateKey(2147483651, $hkpath)
              }
              #change the DWORD value to 1
              $rslt = $reg.SetDWORDValue(2147483651, $hkpath, "RtfFiles", 1)
              $reg = $null                
            }
            
            #this is a sanity check to ensure that the previous applyfix (if enabled)
            #worked
            $blockrtfdword = Get-RemoteRegistryValue $h.Name 4 $hkpath
            if($blockrtfdword) {
              if($blockrtfdword.Name -eq "RtfFiles" -and $blockrtfdword.Value -eq 1) {
                $blocking = $true 
              }
            }
            if($blocking) {
              $hoststat | Add-Member -MemberType NoteProperty -Name "AppliedBlock" -Value "True"
            }
            else {
              $hoststat | Add-Member -MemberType NoteProperty -Name "AppliedBlock" -Value "False"
            }
          }
          $hoststats += $hoststat
        }
      }
      else {
        #word 2003 was not installed. nothing left to do.
        $hoststat = New-Object PSObject
        $hoststat | Add-Member -MemberType NoteProperty -Name "Computer" -Value $h.Name
        $hoststat | Add-Member -MemberType NoteProperty -Name "Word2003Installed" -Value "False"
        $hoststat | Add-Member -MemberType NoteProperty -Name "Profile" -Value ""
        $hoststat | Add-Member -MemberType NoteProperty -Name "BlockingRTF" -Value ""
        $hoststat | Add-Member -MemberType NoteProperty -Name "AppliedBlock" -Value ""
        $hoststats += $hoststat
      }
    }
    else {
      $PSAlert.Add("Unable to connect to $($h.Name)", 2)
    }
  }
  
  if($hoststats) {
    if($showintab) {
      $PSTab.AddObjectGrid($hoststats, "KB2953095 Results")
      Write-Output "KB2953095 Results Tab Created."
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