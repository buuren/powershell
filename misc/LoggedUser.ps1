function get-logedonuser {
param (
 [string]$computername = $env:COMPUTERNAME
)
Get-WmiObject -Class Win32_LogonSession -ComputerName $computername |
foreach {
 $data = $_            

 $id = $data.__RELPATH -replace """", "'"
 $q = "ASSOCIATORS OF {$id} WHERE ResultClass = Win32_Account"
 Get-WmiObject -ComputerName $computername -Query $q |
 select @{N="User";E={$($_.Caption)}},
 @{N="LogonTime";E={$data.ConvertToDateTime($data.StartTime)}}
}
}

$Dir = get-childitem C:\ -recurse
$List = $Dir | where {$_.extension -eq ".ps1"}
$List | format-table name, lastWriteTime | sort lastWriteTime
