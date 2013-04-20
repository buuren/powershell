$computer = [ADSI]("WinNT://$env:COMPUTERNAME,computer")
$Users = $computer.psbase.children |where{$_.psbase.schemaclassname -eq "User"}

foreach ($member in $Users.psbase.syncroot) {

$UserName = $member.name
$user = [adsi]("WinNT://$env:COMPUTERNAME/$UserName")
$user.psbase.Invoke("groups") |foreach {
$group = $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)

"$UserName : $group "
}

}

