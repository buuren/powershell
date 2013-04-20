#powershell -command "C:\Estel\cobian\bat\cobianbackup.ps1"
#################
# Powershell Allows The Loading of .NET Assemblies
# Load the Security assembly to use with this script 
#################
[Reflection.Assembly]::LoadWithPartialName("System.Security")

#################
# This function is to Encrypt A String.
# $string is the string to encrypt, $passphrase is a second security "password" that has to be passed to decrypt.
# $salt is used during the generation of the crypto password to prevent password guessing.
# $init is used to compute the crypto hash -- a checksum of the encryption
#################
function Encrypt-String($String, $Passphrase, $salt="qwertyuFGHAJksldacvbnm,23456789", $init="POKNB rgth264yhdn", [switch]$arrayOutput)
{
	# Create a COM Object for RijndaelManaged Cryptography
	$r = new-Object System.Security.Cryptography.RijndaelManaged
	# Convert the Passphrase to UTF8 Bytes
	$pass = [Text.Encoding]::UTF8.GetBytes($Passphrase)
	# Convert the Salt to UTF Bytes
	$salt = [Text.Encoding]::UTF8.GetBytes($salt)

	# Create the Encryption Key using the passphrase, salt and SHA1 algorithm at 256 bits
	$r.Key = (new-Object Security.Cryptography.PasswordDeriveBytes $pass, $salt, "SHA1", 5).GetBytes(32) #256/8
	# Create the Intersecting Vector Cryptology Hash with the init
	$r.IV = (new-Object Security.Cryptography.SHA1Managed).ComputeHash( [Text.Encoding]::UTF8.GetBytes($init) )[0..15]
	
	# Starts the New Encryption using the Key and IV   
	$c = $r.CreateEncryptor()
	# Creates a MemoryStream to do the encryption in
	$ms = new-Object IO.MemoryStream
	# Creates the new Cryptology Stream --> Outputs to $MS or Memory Stream
	$cs = new-Object Security.Cryptography.CryptoStream $ms,$c,"Write"
	# Starts the new Cryptology Stream
	$sw = new-Object IO.StreamWriter $cs
	# Writes the string in the Cryptology Stream
	$sw.Write($String)
	# Stops the stream writer
	$sw.Close()
	# Stops the Cryptology Stream
	$cs.Close()
	# Stops writing to Memory
	$ms.Close()
	# Clears the IV and HASH from memory to prevent memory read attacks
	$r.Clear()
	# Takes the MemoryStream and puts it to an array
	[byte[]]$result = $ms.ToArray()
	# Converts the array c Base 64 to a string and returns
	return [Convert]::ToBase64String($result)
}

function Decrypt-String($Encrypted, $Passphrase, $salt="qwertyuFGHAJksldacvbnm,23456789", $init="POKNB rgth264yhdn")
{
	# If the value in the Encrypted is a string, convert it to Base64
	if($Encrypted -is [string]){
		$Encrypted = [Convert]::FromBase64String($Encrypted)
   	}

	# Create a COM Object for RijndaelManaged Cryptography
	$r = new-Object System.Security.Cryptography.RijndaelManaged
	# Convert the Passphrase to UTF8 Bytes
	$pass = [Text.Encoding]::UTF8.GetBytes($Passphrase)
	# Convert the Salt to UTF Bytes
	$salt = [Text.Encoding]::UTF8.GetBytes($salt)

	# Create the Encryption Key using the passphrase, salt and SHA1 algorithm at 256 bits
	$r.Key = (new-Object Security.Cryptography.PasswordDeriveBytes $pass, $salt, "SHA1", 5).GetBytes(32) #256/8
	# Create the Intersecting Vector Cryptology Hash with the init
	$r.IV = (new-Object Security.Cryptography.SHA1Managed).ComputeHash( [Text.Encoding]::UTF8.GetBytes($init) )[0..15]


	# Create a new Decryptor
	$d = $r.CreateDecryptor()
	# Create a New memory stream with the encrypted value.
	$ms = new-Object IO.MemoryStream @(,$Encrypted)
	# Read the new memory stream and read it in the cryptology stream
	$cs = new-Object Security.Cryptography.CryptoStream $ms,$d,"Read"
	# Read the new decrypted stream
	$sr = new-Object IO.StreamReader $cs
	# Return from the function the stream
	Write-Output $sr.ReadToEnd()
	# Stops the stream	
	$sr.Close()
	# Stops the crypology stream
	$cs.Close()
	# Stops the memory stream
	$ms.Close()
	# Clears the RijndaelManaged Cryptology IV and Key
	$r.Clear()
}

# This clears the screen of the output from the loading of the assembly.

# $me will never = 1, so It will run indefinately

write-host "To End This Application, Close the Window"	
#$string = read-host "Please Enter User Password"
$encrypted = Encrypt-String $string "MyLolpasswordSucksBallsf"

$decrypted = Decrypt-String "WZDCgsfR5+zlXp1wgiO9kA==" "MyLolpasswordSucksBallsf"

$ProcessActive = Get-Process cbInterface* -ErrorAction SilentlyContinue
if($ProcessActive -eq $null) {
"Process dont work"
} else {
"Killing cbInterface"
Stop-Process -processname cbInterface*
}

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
#--------------------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------------------#

function InstallCobian {
"Starting instalCobian"
<#if ($OSName -match "7") {
"OS is 7. Starting to tweak VSS"

$vssstatus = (Get-Service | where {$_.Name -eq "VSS"}).Status
if ($vssstatus -eq "stopped") {
    "stopped"
    #Start-Service VSS
} else {
    "running"
}
    
if (Get-ItemProperty -Name "$pc_name\Administrator" -path "HKLM:\SYSTEM\CurrentControlSet\Services\VSS\VssAccessControl" -erroraction silentlycontinue) { 
    "Registry key:" + " " + "$pc_name\Administrator" + "in HKLM:\SYSTEM\CurrentControlSet\Services\VSS\VssAccessControl already exists." 
} else {
    New-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\VSS\VssAccessControl" -Name "$pc_name\Administrator" -Type DWORD -Value 1
    New-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\VSS\VssAccessControl" -Name "NT Authority\System" -Type DWORD -Value 1
} 
    
} else {
    "OS is XP. No need to tweak VSS"
}
#>
"Launching cbsetup.exe"
#Invoke-expression  \\ubuntu64\sys$\script\cobian\CobianBackup10.exe
\\ubuntu64\sys$\script\cobian\CobianBackup10.exe
start-sleep 30
$homedir = "C:\Estel"

$acl = (Get-Item $homedir).GetAccessControl("Access")
if ($acl.AreAccessRulesProtected) { $acl.Access | % {$acl.purgeaccessrules($_.IdentityReference)} }
else {
		$isProtected = $true 
		$preserveInheritance = $false
		$acl.SetAccessRuleProtection($isProtected, $preserveInheritance) 
	 }
$account = @('Administrator', 'NT AUTHORITY\SYSTEM')
$rights=[System.Security.AccessControl.FileSystemRights]::FullControl
$inheritance=[System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"
$propagation=[System.Security.AccessControl.PropagationFlags]::None
$allowdeny=[System.Security.AccessControl.AccessControlType]::Allow

foreach ($accounts in $account) {
$dirACE=New-Object System.Security.AccessControl.FileSystemAccessRule ($accounts,$rights,$inheritance,$propagation,$allowdeny)
$ACL.AddAccessRule($dirACE)
Set-Acl -aclobject $ACL -Path $homedir
}
Write-Host $homedir Permissions added


"Backup location $destination_line"
mkdir C:\Estel\cobian\bat

copy \\ubuntu64\sys$\script\cobian\backup.bat C:\Estel\cobian\bat\backup.bat
copy \\ubuntu64\sys$\script\cobian\cobianbackup.ps1 C:\Estel\cobian\bat\cobianbackup.ps1
$hours = Get-Random -Minimum 10 -Maximum 16
$minutes = Get-Random -Minimum 0 -Maximum 59
$time = "$hours" + ":" + "$minutes" + ":" + "00"
"Creating schedule task..."
#Invoke-expression  schtasks /create /tn "daily_backup" /tr "C:\Estel\cobian\bat\backup.bat" /sc daily /st $time /ru Administrator /rp $decrypted
Invoke-expression -Command "C:\Windows\System32\schtasks.exe /create /tn 'daily_backup' /tr 'C:\Estel\cobian\bat\backup.bat' /sc daily /st 13:30:00 /ru Administrator /rp $decrypted"
"Done!"

}
#--------------------------------------------------------------------------------------------------#
#------------------C:\Users\user>schtasks /create /tn "daily_backup" /tr "C:\Estel\cobian\bat\backup.bat" /sc daily /st 14:10:00 /ru Administrator--------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------------------#

function UpdateCobian {
if (!(Test-Path -path C:\Estel\cobian\DB\full.lst)) {
New-Item C:\Estel\cobian\DB\full.lst -type file
} else {
del C:\Estel\cobian\DB\full.lst
New-Item C:\Estel\cobian\DB\full.lst -type file
}

if (!(Test-Path -path C:\Estel\cobian\DB\diff.lst)) {
New-Item C:\Estel\cobian\DB\diff.lst -type file
} else {
del C:\Estel\cobian\DB\diff.lst
New-Item C:\Estel\cobian\DB\diff.lst -type file
}

if (!(Test-Path -path C:\Estel\cobian\DB\outlook.lst)) {
New-Item C:\Estel\cobian\DB\outlook.lst -type file
} else {
del C:\Estel\cobian\DB\outlook.lst
New-Item C:\Estel\cobian\DB\outlook.lst -type file
}

if (!(Test-Path -path C:\Estel\source_full.txt)) {
New-item C:\Estel\source_full.txt -type file
} else {
del C:\Estel\source_full.txt
New-item C:\Estel\source_full.txt -type file
}

if (!(Test-Path -path C:\Estel\exclude_full.txt)) {
New-item C:\Estel\exclude_full.txt -type file
} else {
del C:\Estel\exclude_full.txt
New-item C:\Estel\exclude_full.txt -type file
}

if (!(Test-Path -path C:\Estel\source_diff.txt)) {
New-item C:\Estel\source_diff.txt -type file
} else {
del C:\Estel\source_diff.txt
New-item C:\Estel\source_diff.txt -type file
}

if (!(Test-Path -path C:\Estel\exclude_diff.txt)) {
New-item C:\Estel\exclude_diff.txt -type file
} else {
del C:\Estel\exclude_diff.txt
New-item C:\Estel\exclude_diff.txt -type file
}

if (!(Test-Path -path C:\Estel\source_outlook.txt)) {
New-item C:\Estel\source_outlook.txt -type file
} else {
del C:\Estel\source_outlook.txt
New-item C:\Estel\source_outlook.txt -type file
}

if (!(Test-Path -path C:\Estel\exclude_outlook.txt)) {
New-item C:\Estel\exclude_outlook.txt -type file
} else {
del C:\Estel\exclude_outlook.txt
New-item C:\Estel\exclude_outlook.txt -type file
}


if ($OSName -eq "Microsoft Windows XP Professional") { #if1 
"OS is XP..."
$findprofile = Get-childItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' | % {Get-ItemProperty $_.pspath }

foreach ($userpro in $findprofile)  {
$lol1 = $userpro | Where-Object {$_.ProfileImagePath -ne "C:\WINDOWS\system32\config\systemprofile"}
$lol2 = $lol1 | Where-Object {$_.ProfileImagePath -ne "C:\Documents and Settings\LocalService"}
$lol3 = $lol2 | Where-Object {$_.ProfileImagePath -ne "C:\Documents and Settings\NetworkService"}
$lol4 = $lol3 | Where-Object {$_.ProfileImagePath -notlike "*Administrator*"}
$lol5 = $lol4 | Where-Object {$_.ProfileImagePath -notlike "*Guest*"}
$sqlread_functionusers = $lol5.ProfileImagePath

        foreach ($sqloneuser in $sqlread_functionusers) {
            
            if ($sqloneuser -eq $null) {
            } else {
            $source_line = '"1' + ',""' + "$sqloneuser\My Documents" + '""","1,' + '""' + "$sqloneuser\Desktop" + '"""' | Out-File C:\Estel\source_full.txt -append
            $exclude_line = '"1,""' + "$sqloneuser\My Documents\Downloads" + '"",0,0000000000000000000000000000000000000000000000000000000000000000"' + ',"1,""' + "$sqloneuser\My Documents\Outlook Files" + '"",0,0000000000000000000000000000000000000000000000000000000000000000"' | Out-File C:\Estel\exclude_full.txt -append
            }
        }
    } 
$source_line = [system.string]::Join(",",(get-content C:\Estel\source_full.txt))
"Source=" + $source_line | Out-File C:\Estel\source_new_full.txt
$source_line_last_full = cat C:\Estel\source_new_full.txt
#-----------------------------------------------------------------------#
$exclude_line = [system.string]::Join(",",(get-content C:\Estel\exclude_full.txt))
"Exclusions=" + $exclude_line | Out-File C:\Estel\exclude_new_full.txt
$exclude_line_last_full = cat C:\Estel\exclude_new_full.txt
} else  {
"not win xp"
}
     
if ($OSName -match "7") {
"OS name is 7"
$findprofile = Get-childItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' | % {Get-ItemProperty $_.pspath }
foreach ($userpro in $findprofile)  { 

$lol1 = $userpro | Where-Object {$_.ProfileImagePath -ne "C:\Windows\system32\config\systemprofile"}
$lol2 = $lol1 | Where-Object {$_.ProfileImagePath -ne "C:\Windows\ServiceProfiles\LocalService"}
$lol3 = $lol2 | Where-Object {$_.ProfileImagePath -ne "C:\Windows\ServiceProfiles\NetworkService"}
$lol4 = $lol3 | Where-Object {$_.ProfileImagePath -ne "C:\Users\UpdatusUser"}
$lol5 = $lol4 | Where-Object {$_.ProfileImagePath -notlike "*Administrator*"}
$lol6 = $lol5 | Where-Object {$_.ProfileImagePath -notlike "*Classic*"}
$lol7 = $lol6 | Where-Object {$_.ProfileImagePath -notlike "*Default*"}

    $sqlread_functionusers = $lol7.ProfileImagePath

            foreach ($sqloneuser in $sqlread_functionusers) {
            
            if ($sqloneuser -eq $null) {
            } else {
            $source_line = '"1' + ',""' + "$sqloneuser\Documents" + '""","1,' + '""' + "$sqloneuser\Desktop" + '""","1,""' + "$sqloneuser\Pictures" + '"""' | Out-File C:\Estel\source_full.txt -append
            $exclude_line = '"1' + ',""' + "$sqloneuser\Documents\Outlook Files" + '"",0,0000000000000000000000000000000000000000000000000000000000000000"' | Out-File C:\Estel\exclude_full.txt -append
            }
        }
    }
$source_line = [system.string]::Join(",",(get-content C:\Estel\source_full.txt))
"Source=" + $source_line | Out-File C:\Estel\source_new_full.txt
$source_line_last_full = cat C:\Estel\source_new_full.txt
#------------------------------------------------#
$exclude_line = [system.string]::Join(",",(get-content C:\Estel\exclude_full.txt))
"Exclusions=" + $exclude_line | Out-File C:\Estel\exclude_new_full.txt
$exclude_line_last_full = cat C:\Estel\exclude_new_full.txt
} else  {
"not win 7"
}    

$destination_line = 'Destination=' + '"1,' + $backup_destination + "'"

'{11//' | Out-File C:\Estel\cobian\DB\full.lst -append
'Id={4A51514B-4756-476C-B29A-1BA2DE5ACEC2}' | Out-File C:\Estel\cobian\DB\full.lst -append
'Name=full' | Out-File C:\Estel\cobian\DB\full.lst -append
'Group=' | Out-File C:\Estel\cobian\DB\full.lst -append
'Enabled=true' | Out-File C:\Estel\cobian\DB\full.lst -append
'Include subdirectories=true' | Out-File C:\Estel\cobian\DB\full.lst -append
'Create separated backups=true' | Out-File C:\Estel\cobian\DB\full.lst -append
'Use attributes=true' | Out-File C:\Estel\cobian\DB\full.lst -append
'Use VSC=true' | Out-File C:\Estel\cobian\DB\full.lst -append
'Backup type=0' | Out-File C:\Estel\cobian\DB\full.lst -append
'Priority=0' | Out-File C:\Estel\cobian\DB\full.lst -append
"$source_line_last_full" | Out-File C:\Estel\cobian\DB\full.lst -append #source_line
"$destination_line" | Out-File C:\Estel\cobian\DB\full.lst -Append  #destination_line
'Schedule type=1' | Out-File C:\Estel\cobian\DB\full.lst -append
'Select days of the week=false' | Out-File C:\Estel\cobian\DB\full.lst -append
'Order of Day of the week=1' | Out-File C:\Estel\cobian\DB\full.lst -append
'Day of the week=1' | Out-File C:\Estel\cobian\DB\full.lst -append
'Date/Time=0100000011100100000011100010110010000000001111010000101110101010' | Out-File C:\Estel\cobian\DB\full.lst -append
'Day of the month=1' | Out-File C:\Estel\cobian\DB\full.lst -append
'Month=1' | Out-File C:\Estel\cobian\DB\full.lst -append
'Timer=180' | Out-File C:\Estel\cobian\DB\full.lst -append
'Timer from=0100000011100100000011100010000000000000000000000000000000000000' | Out-File C:\Estel\cobian\DB\full.lst -append
'Timer to=0100000011100100000011100011111111111111111001111011101000110111' | Out-File C:\Estel\cobian\DB\full.lst -append
'Full copies=0' | Out-File C:\Estel\cobian\DB\full.lst -append
'Differental copies=0' | Out-File C:\Estel\cobian\DB\full.lst -append
'One full every=0' | Out-File C:\Estel\cobian\DB\full.lst -append
'Use fixed day=false' | Out-File C:\Estel\cobian\DB\full.lst -append
'Fixed day=1' | Out-File C:\Estel\cobian\DB\full.lst -append
'Compression=1' | Out-File C:\Estel\cobian\DB\full.lst -append
'Compress individually=false' | Out-File C:\Estel\cobian\DB\full.lst -append
'Split=0' | Out-File C:\Estel\cobian\DB\full.lst -append
'Custom size=4300000000' | Out-File C:\Estel\cobian\DB\full.lst -append
'Comment=Cobian Backup 11 Gravity' | Out-File C:\Estel\cobian\DB\full.lst -append
'Encryption=0' | Out-File C:\Estel\cobian\DB\full.lst -append
'Passphrase=fQB8AH0AdwBoAGYAeQBxAHAAbwAoAHQAAgADABQAcwBvAHUAdAAdAAMAcgB6AHIAbAAEABgAAAB2AB0AeAAJAGMAdwBqACwAEAABAH8ABwBkAAAAZABsAHMAbgAYADwAbwAwAA==' | Out-File C:\Estel\cobian\DB\full.lst -append
"$exclude_line_last_full" | Out-File C:\Estel\cobian\DB\full.lst -append #exclude list
'Inclusions=' | Out-File C:\Estel\cobian\DB\full.lst -append
'Pre backup events=' | Out-File C:\Estel\cobian\DB\full.lst -append
'Post backup events=' | Out-File C:\Estel\cobian\DB\full.lst -append
'Abort if pre-event fails=false' | Out-File C:\Estel\cobian\DB\full.lst -append
'Abort if post-event fails=false' | Out-File C:\Estel\cobian\DB\full.lst -append
'Mirror=false' | Out-File C:\Estel\cobian\DB\full.lst -append
'Absolute paths=false' | Out-File C:\Estel\cobian\DB\full.lst -append
'Always create top directory=true' | Out-File C:\Estel\cobian\DB\full.lst -append
'Clear archive attribute=true' | Out-File C:\Estel\cobian\DB\full.lst -append
'Include backup type=true' | Out-File C:\Estel\cobian\DB\full.lst -append
'Delete empty directories=false' | Out-File C:\Estel\cobian\DB\full.lst -append
'Impersonate=false' | Out-File C:\Estel\cobian\DB\full.lst -append
'Abort if impersonation fails=false' | Out-File C:\Estel\cobian\DB\full.lst -append
'Run as User name=' | Out-File C:\Estel\cobian\DB\full.lst -append
'Run as Domain=.' | Out-File C:\Estel\cobian\DB\full.lst -append
'Run as Password=dgBzAHMAewBoAHAAfgB/AGcAcgA6AG4ADgADAAEAcwByAHUAaAAdAAoAcgB7AHIAYwAEAAAAAAB9AB0AeAAJAHoAdwBhACwACwABAG0AFwB5ABIAcAB6AHcAdAAYADQAbgAnAA==' | Out-File C:\Estel\cobian\DB\full.lst -append
'//11}' | Out-File C:\Estel\cobian\DB\full.lst -append
#==========================================================================================================================================#
#==========================================================================================================================================#
#==========================================================================================================================================#
#==========================================================================================================================================#
if ($OSName -eq "Microsoft Windows XP Professional") {
"OS is XP..."
$findprofile = Get-childItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' | % {Get-ItemProperty $_.pspath }
foreach ($userpro in $findprofile)  {
$lol1 = $userpro | Where-Object {$_.ProfileImagePath -ne "C:\WINDOWS\system32\config\systemprofile"}
$lol2 = $lol1 | Where-Object {$_.ProfileImagePath -ne "C:\Documents and Settings\LocalService"}
$lol3 = $lol2 | Where-Object {$_.ProfileImagePath -ne "C:\Documents and Settings\NetworkService"}
$lol4 = $lol3 | Where-Object {$_.ProfileImagePath -notlike "*Administrator*"}
$lol5 = $lol4 | Where-Object {$_.ProfileImagePath -notlike "*Guest*"}
$sqlread_functionusers = $lol5.ProfileImagePath

        foreach ($sqloneuser in $sqlread_functionusers) {
            
            if ($sqloneuser -eq $null) {
            } else {
            $source_line = '"1' + ',""' + "$sqloneuser\My Documents" + '""","1,' + '""' + "$sqloneuser\Desktop" + '"""' | Out-File C:\Estel\source_diff.txt -append
            $exclude_line = '"1,""' + "$sqloneuser\My Documents\Downloads" + '"",0,0000000000000000000000000000000000000000000000000000000000000000"' + ',"1,""' + "$sqloneuser\My Documents\Outlook Files" + '"",0,0000000000000000000000000000000000000000000000000000000000000000"' | Out-File C:\Estel\exclude_diff.txt -append
            }
        }
    } 
$source_line = [system.string]::Join(",",(get-content C:\Estel\source_diff.txt))
"Source=" + $source_line | Out-File C:\Estel\source_new_diff.txt
$source_line_last_diff = cat C:\Estel\source_new_diff.txt
#-----------------------------------------------------------------------#
$exclude_line = [system.string]::Join(",",(get-content C:\Estel\exclude_diff.txt))
"Exclusions=" + $exclude_line | Out-File C:\Estel\exclude_new_diff.txt
$exclude_line_last_diff = cat C:\Estel\exclude_new_diff.txt
} else  {
"not win XP"
}
     
    if ($OSName -match "7") {
    "OS name is 7"
    $findprofile = Get-childItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' | % {Get-ItemProperty $_.pspath }
    foreach ($userpro in $findprofile)  { 

    $lol1 = $userpro | Where-Object {$_.ProfileImagePath -ne "C:\Windows\system32\config\systemprofile"}
    $lol2 = $lol1 | Where-Object {$_.ProfileImagePath -ne "C:\Windows\ServiceProfiles\LocalService"}
    $lol3 = $lol2 | Where-Object {$_.ProfileImagePath -ne "C:\Windows\ServiceProfiles\NetworkService"}
    $lol4 = $lol3 | Where-Object {$_.ProfileImagePath -ne "C:\Users\UpdatusUser"}
    $lol5 = $lol4 | Where-Object {$_.ProfileImagePath -notlike "*Administrator*"}
    $lol6 = $lol5 | Where-Object {$_.ProfileImagePath -notlike "*Classic*"}
    $lol7 = $lol6 | Where-Object {$_.ProfileImagePath -notlike "*Default*"}

    $sqlread_functionusers = $lol7.ProfileImagePath

            foreach ($sqloneuser in $sqlread_functionusers) {
            
            if ($sqloneuser -eq $null) {
            } else {
            $source_line = '"1' + ',""' + "$sqloneuser\Documents" + '""","1,' + '""' + "$sqloneuser\Desktop" + '""","1,""' + "$sqloneuser\Pictures" + '"""' | Out-File C:\Estel\source_diff.txt -append
            $exclude_line = '"1' + ',""' + "$sqloneuser\Documents\Outlook Files" + '"",0,0000000000000000000000000000000000000000000000000000000000000000"' | Out-File C:\Estel\exclude_diff.txt -append
            }
        }
    }
$source_line = [system.string]::Join(",",(get-content C:\Estel\source_diff.txt))
"Source=" + $source_line | Out-File C:\Estel\source_new_diff.txt
$source_line_last_diff = cat C:\Estel\source_new_diff.txt
#------------------------------------------------#
$exclude_line = [system.string]::Join(",",(get-content C:\Estel\exclude_diff.txt))
"Exclusions=" + $exclude_line | Out-File C:\Estel\exclude_new_diff.txt
$exclude_line_last_diff = cat C:\Estel\exclude_new_diff.txt
} else  {
"not win 7"
}    

$destination_line = 'Destination=' + '"1,' + $backup_destination + "'"

'{11//' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Id={6F331B84-CB5F-40C3-9E49-8B3A556B949E}' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Name=incr' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Group=' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Enabled=true' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Include subdirectories=true' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Create separated backups=true' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Use attributes=true' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Use VSC=true' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Backup type=1' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Priority=0' | Out-File C:\Estel\cobian\DB\diff.lst -append
"$source_line_last_diff"  | Out-File C:\Estel\cobian\DB\diff.lst -append 
"$destination_line" | Out-File C:\Estel\cobian\DB\diff.lst -Append  #destination_line
'Schedule type=1' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Select days of the week=false' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Order of Day of the week=1' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Day of the week=1' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Date/Time=0100000011100100000011100010110010000000001111010000101110101010' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Day of the month=1' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Month=1' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Timer=180' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Timer from=0100000011100100000011100010000000000000000000000000000000000000' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Timer to=0100000011100100000011100011111111111111111001111011101000110111' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Full copies=0' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Differental copies=50' | Out-File C:\Estel\cobian\DB\diff.lst -append
'One full every=0' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Use fixed day=false' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Fixed day=7' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Compression=1' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Compress individually=false' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Split=0' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Custom size=4300000000' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Comment=Cobian Backup 11 Gravity' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Encryption=0' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Passphrase=dgBgAH4AYgB9AGEAYwB2AHMAbwA1AHAACwADAAMAcwBgAHUAegAdABwAcgBnAHIAegAEAAoAAAB2AB0AegAJAH0AdwBsACwADQABAH8AFwBmAAMAdwB8AHYAcwAYACoAaAAyAA==' | Out-File C:\Estel\cobian\DB\diff.lst -append
"$exclude_line_last_diff" | Out-File C:\Estel\cobian\DB\diff.lst -append #exclude list
'Inclusions=' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Pre backup events=' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Post backup events=' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Abort if pre-event fails=false' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Abort if post-event fails=false' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Mirror=false' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Absolute paths=false' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Always create top directory=true' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Clear archive attribute=true' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Include backup type=true' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Delete empty directories=false' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Impersonate=false' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Abort if impersonation fails=false' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Run as User name=' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Run as Domain=.' | Out-File C:\Estel\cobian\DB\diff.lst -append
'Run as Password=YgB9AGcAYQB+AHgAegBgAGcAYAA4AHgACgADAAMAcwBuAHUAewAdAAAAcgB7AHIAaAAEAAYAAAB4AB0AdwAJAGEAdwB0ACwAAAABAGAABgBoABkAZQB7AHgAaAANADgAZQA1AA==' | Out-File C:\Estel\cobian\DB\diff.lst -append
'//11}' | Out-File C:\Estel\cobian\DB\diff.lst -append
#==========================================================================================================================================#
#==========================================================================================================================================#
}

#--------------------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------------------#

if (!(Test-Path -path C:\Estel\cobian)) {
"Installing cobian..."
InstallCobian
} else {
}
UpdateCobian

$ProcessActive = Get-Process cbInterface* -ErrorAction SilentlyContinue
if($ProcessActive -eq $null) {
"Process dont work"
} else {
"Killing cbInterface"
Stop-Process -processname cbInterface*
}


$net_drive = get-wmiobject -class "Win32_MappedLogicalDisk" -namespace "root\CIMV2" | foreach-object {$_.ProviderName}
if ($net_drive -like "*\\192.168.60.202\*") {
    "Backup drive exists"
} else {
    $net = new-object -ComObject WScript.Network
    $net.MapNetworkDrive("r:", "\\192.168.60.202\estelbackup", $false, "backupuser", "1315")
}

if (!(Test-Path -path $backup_destination)) {
mkdir $backup_destination
} else {
}

$findfull = dir $backup_destination | ForEach-Object {$_.Name}
if ($findfull -eq $null) {
    "Starting full backup..."
     Invoke-expression -Command 'C:\Windows\System32\net.exe stop "Cobian Backup 11 Gravity"'
     start-process -filepath "C:\Estel\cobian\Cobian.exe" -argumentlist '"-list:C:\Estel\Cobian\DB\full.lst" -bu -nogui -autoclose' -wait -passthru
     Invoke-expression -Command 'C:\Windows\System32\net.exe start "Cobian Backup 11 Gravity"'
} else {
    "Full backup exists. Start differitantly backup"
     Invoke-expression -Command 'C:\Windows\System32\net.exe stop "Cobian Backup 11 Gravity"'
     start-process -filepath "C:\Estel\cobian\Cobian.exe" -argumentlist '"-list:C:\Estel\Cobian\DB\diff.lst" -bu -nogui -autoclose' -wait -passthru
     Invoke-expression -Command 'C:\Windows\System32\net.exe start "Cobian Backup 11 Gravity"'
}

#Invoke-expression  net stop "Cobian Backup 11 Gravity"
#Invoke-expression  C:\Estel\cobian\Cobian.exe "-list:C:\Estel\Cobian\DB\outlook.lst" -bu -nogui -autoclose
#Invoke-expression  net start "Cobian Backup 11 Gravity"

$findfake = dir $backup_destination | Where-Object {$_.name -like "*full*" -and $_.name -like "*incr*"}
if ($findfake -eq $null) {
} else {

    foreach ($fakes in $findfake) {
    del "$backup_destination\$fakes"
    }
}



$newlogfilefull = ((Get-Date).Day).ToString() + (Get-Date -UFormat %b) + "-full.txt"
$newlogfileerror = ((Get-Date).Day).ToString() + (Get-Date -UFormat %b) + "-error.txt"

$copylog = (gci C:\Estel\cobian\Logs | sort @{expression="LastWriteTime";Descending=$true} | Select -First 1).Name

cat "C:\Estel\cobian\logs\$copylog" | Out-File "$backup_destination\$newlogfilefull"
cat "C:\Estel\cobian\logs\$copylog" | Select-String -Pattern "ERR " | Out-File "$backup_destination\$newlogfileerror" -Width 1920
Invoke-expression -Command "C:\Windows\System32\net.exe use R: /delete /yes"
#"Errors: " + (cat "\\Ubuntu64\sys$\pcinfo\$pc_name\$newlogfileerror" | where {$_ -ne ""} | Measure-Object).Count
