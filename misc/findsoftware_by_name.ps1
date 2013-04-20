#gwmi win32_product 
#(gwmi win32_product | ? {$_.name -match 'office'}).Version | select 1
#$a = (gwmi Win32_product | where {$_.Description -like 'Microsoft Office*' } | Select Version).DisplayVersion
#$a
<#
switch ($a.Version) 
{ 
'14.0.4756.1000' {"2010"} 
'14.0.6024.1000' {"2010 SP1"} 
'12.0.4518.1014' {"2007"} 
'12.0.6214.1000' {"2007 SP1"} 
'12.0.6425.1000' {"2007 SP2"} 
default {"No Excel Found"} 
}
#>
#(gwmi Win32_OperatingSystem).CSDVersion

# PowerShell script to display programs from registry.




$tempoffice = Get-ChildItem HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall | foreach {Get-ItemProperty $_.PsPath} | Where {$_.DisplayName -match "office"}
    for ($i = 0 ; $i -lt $tempoffice.length ; $i++) {
        $tempoffice
}