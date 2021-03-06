New-PSDrive HKU Registry HKEY_USERS

function Search-RegistryKeyValues {
 param(
 [string]$path,
 [string]$valueName
 )
 Get-ChildItem $path -recurse -ea SilentlyContinue | 
 % { 
  if ((Get-ItemProperty -Path $_.PsPath -ea SilentlyContinue) -match $valueName)
  {
   $_.PsPath
  } 
 }
}


$myArray = @()
$final_array = @()
$key = Search-RegistryKeyValues "hku:" "POP3 User Name"

$search_key = (Get-ItemProperty $key)

foreach ($onekey in $search_key ) {
    $new_t = $OneKey."POP3 User Name"
    #$m = "0" + "$($onekey."Account name")"
    #$m
    #$tekst = $m.Split() | %{[Convert]::ToString($_, 16)} | %{[Convert]::ToInt32($_,16)} | %{[Convert]::ToChar($_)}
    #$tekst
    #$sort = [char[]][int[]]$tekst
    #$sort = $sort | where {$_ -ne 0 }
    #$sort
    #$new_t = ("$sort" -replace " ", "")
    $myArray += $new_t
}   

$myarray | select -uniq

Remove-PSDrive HKU