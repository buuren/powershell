function Get-InstalledAppReg ([string]$ComputerName) {
  $RegPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
  $BaseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $ComputerName)
  $OpenSubKey = $BaseKey.OpenSubKey($RegPath)
  $OpenSubKey.GetSubKeyNames() | ForEach {
    $Path = "$RegPath\$_"
    $BaseKey.OpenSubKey($Path).GetValue("DisplayName")
  }
}
$officeversionTemp = Get-InstalledAppReg | Select-String "microsoft office 20"
$officeversionTemp
"------------------"
if ($officeversionTemp -match "2010") {
        $officeversion1 = "2010"
} else {
        $officeversion1 = ""
}

if ($officeversionTemp -match "2007") {
      $officeversion2 = "2007"
} else {
      $officeversion2 = ""
}

if ($officeversionTemp -match "2003") {
      $officeversion3 = "2003"
} else {
      $officeversion3 = ""
}

if ($officeversionTemp -match "2000") {
      $officeversion4 = "2000"
} else {
      $officeversion4 = ""
}


if ($officeversionTemp -notmatch "2000" -and $officeversionTemp -notmatch "2003" -and $officeversionTemp -notmatch "2007" -and $officeversionTemp -notmatch "2010") {
      $officeversion5 = "Unknown"
} else {
    $officeversion5 = ""
}

$officeversionLast = "$officeversion1`n$officeversion2`n$officeversion3`n$officeversion4`n$officeversion5`n"
$officeversion = $officeversionLast -replace ("`n","")
$officeversion
#$officeversion = $officeversionTemp -replace "[^\d]"