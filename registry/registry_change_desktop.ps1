$newPath = 'C:\Users\Public\Public Desktop'  
$key1 = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"  
$key2 = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"  
set-ItemProperty -path $key1 -name Desktop $newPath  
set-ItemProperty -path $key2 -name Desktop $newPath