$pc_name = (gwmi Win32_ComputerSystem).Name
$OSname = (gwmi Win32_OperatingSystem).Caption
$month_number = (Get-Date).Month

if ($month_number -eq "1") {
$month_location = "januar"
} elseif ($month_number -eq "2") {
$month_location = "februar"
} elseif ($month_number -eq "3") {
$month_location = "mart"
} elseif ($month_number -eq "4") {
$month_location = "aprel"
} elseif ($month_number -eq "5") {
$month_location = "mai"
} elseif ($month_number -eq "6") {
$month_location = "juuni"
} elseif ($month_number -eq "7") {
$month_location = "juuli"
} elseif ($month_number -eq "8") {
$month_location = "august"
} elseif ($month_number -eq "9") {
$month_location = "september"
} elseif ($month_number -eq "10") {
$month_location = "oktoober"
} elseif ($month_number -eq "11") {
$month_location = "november"
} elseif ($month_number -eq "12") {
$month_location = "detsember"
} else {
break;
}

if (!(Test-Path -path C:\Estel)) {
mkdir C:\Estel\
} else {
}

$backup_destination = "\\192.168.60.202\estelbackup\$month_location\$pc_name"

$net_drive = get-wmiobject -class "Win32_MappedLogicalDisk" -namespace "root\CIMV2" | foreach-object {$_.ProviderName}
if ($net_drive -like "*\\192.168.60.202\*") {
    "Backup drive exists"
} else {
    $net = new-object -ComObject WScript.Network
    $net.MapNetworkDrive("r:", "\\192.168.60.202\estelbackup", $false, "backupuser", "1315")
}
$backup_destination
$findfull = dir $backup_destination | ForEach-Object {$_.Name}
if ($findfull -eq $null) {
    "Starting full backup..."
    # cmd /c net stop "Cobian Backup 11 Gravity"
     #cmd /c C:\Estel\cobian\Cobian.exe "-list:C:\Estel\Cobian\DB\full.lst" -bu -nogui -autoclose
     #cmd /c net start "Cobian Backup 11 Gravity"
} else {
    "Full backup exists. Start differitantly backup"
     #cmd /c net stop "Cobian Backup 11 Gravity"
     #cmd /c C:\Estel\cobian\Cobian.exe "-list:C:\Estel\Cobian\DB\diff.lst" -bu -nogui -autoclose
     #cmd /c net start "Cobian Backup 11 Gravity"
}

cmd /c net use R: /delete /yes