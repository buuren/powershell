#Delete old tables
#Delete old files
#Extract backup
#Replace configuration.php
#Upload database

#$date_year = Get-Date -Format "yyyy-MM-dd"
#$backup_name = "backup_" + $date_year + "_21-30_estel.ee-sql-nodrop.tar"
#$backup_name = "backup_2012-10-29_21-30_estel.ee-sql-nodrop.tar"
#$old_backup = "E:\website\" + $backup_name
#"Starting to update website"
"Dropping all tables on d34221sd48517..."
$delete_tables = "F:\website\test.sql"
mysql -h 192.168.60.134 -u estellog -p123 d34221sd48517 -e "source $delete_tables"
"Done."
"Deleting old joomla files..."
Remove-Item \\ubuntu64\www$\estel\* -Recurse
"Done"
"Extracting backup files..."

$old_backup = ((dir F:\website |  where {$_.extension -eq ".tar"} | sort -property LastWriteTime -desc)[0]).name

cmd /c 7z x F:\website\$old_backup -o\\ubuntu64\www$\estel -y
"Done"
"Copying configuration.php..."
copy F:\website\configuration.php \\ubuntu64\www$\estel\
"Done"
"Uploading new tables to d34221sd48517..."
$upload_tables = "\\ubuntu64\www$\estel\administrator\backups\database-sql.sql"
mysql -h 192.168.60.134 -u estellog -p123 --default-character-set=utf8 d34221sd48517 -e "source $upload_tables"
"Done"
"Website update completed"
