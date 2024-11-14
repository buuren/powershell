

$net_drive = get-wmiobject -class "Win32_MappedLogicalDisk" -namespace "root\CIMV2" | foreach-object {$_.ProviderName}

if ($net_drive -like "*\\192.168.60.103\*") {
    "Backup drive exists"
} else {
    "Creating.."
	net use R: \\192.168.50.103\backup$ /user:.\UserName PassW0rd
}

# get existing shadow copies
$shadow = get-wmiobject win32_shadowcopy
"There are {0} shadow copies on this sytem" -f $shadow.count
""