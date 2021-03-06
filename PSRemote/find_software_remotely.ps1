##################################################################### 
## 
## Function: Get-RemoteInstallInformation 
## Purpose: Returns an arrayList of hashes where each hash represents an entry in the uninstall registry key. 
## The hashes have these Key/Value pairs: 
## DisplayName -> The DisplayName value if it is populated 
## DisplayVersion -> The DisplayVersion value if it is populated 
## InstallDate -> The InstallDate value if it is populated 
## UnInstallString - The UninstallString value if it is populated 
## RegKey -> The actual registry SubKey Object 
## 
## Parameters: 
## ComputerName - The name of the machine to retrieve the information from. 
## 
## Example: 
## Get-RemoteInstallInformation ldmdlabwks051 
## This would return the installed program information for ldmdlabwks051 
## 
##################################################################### 
function Get-RemoteInstallInformation { 
param( 
$ComputerName 
) 

$result = New-Object System.Collections.ArrayList 
$key = ([Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $ComputerName)).OpenSubKey("Software\Microsoft\Windows\CurrentVersion\Uninstall") 

foreach ($sub in $key.GetSubKeyNames())  { 
$temp = @{} 
$subKey = $key.OpenSubkey($sub) 

$temp["DisplayName"] = $subKey.GetValue("DisplayName") 
$temp["DisplayVersion"] = $subKey.GetValue("DisplayVersion") 
$temp["InstallDate"] = $subKey.GetValue("InstallDate") 
$temp["UninstallString"] = $subKey.GetValue("UninstallString") 
$temp["RegKey"] = $subKey 
$result.Add($temp) | Out-Null 
    } 
    return $result 
}
