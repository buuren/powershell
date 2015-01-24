<#
this was a block of notes
#>

import-module activedirectory  
md c:\SCRIPT\
$filepath = write c:\SCRIPT\staleaduser.csv
$DaysInactive = 90  
$time = (Get-Date).Adddays(-($DaysInactive)) 

# Get all AD User with lastLogonTimestamp less than our time and set to disable
$staleusers = get-aduser -filter {enabled -eq $false -and LastLogonTimeStamp -lt $time} -searchbase "ou=YourTopOU,dc=DOMAIN,dc=COM" -property LastLogonTimeStamp
$staleusers | export-csv $filepath

#Email a Report

$messageParameters = @{                        
                Subject = "Stale AD User Report"                        
                Body = "Please see the attached report for disabled AD user accounts older than 90 days.

These user accounts will be move to the PendingDeletion OU.  Another script will run tomorrow deleting the objects.

Please move any necessary users beforehand!"
                From = "your@sending.address"                        
                To = "your@receiving.address"                        
                SmtpServer = "IP of your SMTP"
                Attachments = $filepath
                }
Send-MailMessage @messageparameters

$staleusers | move-adobject -TargetPath "OU=PendingDeletion,DC=DOMAIN,DC=COM"
