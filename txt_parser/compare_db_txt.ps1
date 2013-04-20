#SELECT pc_name, COUNT(*) TotalCount FROM stats GROUP BY pc_Name HAVING (COUNT(pc_name) > 1)

del \\server\script\powershell\pc_list_temp.txt
[void][system.reflection.assembly]::LoadWithPartialName("MySql.Data")
$dbconnect = New-Object -TypeName MySql.Data.MySqlClient.MySqlConnection
$dbconnect.ConnectionString = (“server=ubuntu64;user id=log;password=PA$$W0RD;database=statistic;pooling=false”)
$dbconnect.Open()
$sql = New-Object MySql.Data.MySqlClient.MySqlCommand
$sql.Connection = $dbconnect
$sql.CommandText = "select pc_name from stats”
        $argument = $sql.ExecuteReader()        
        while ($argument.Read())
                {
        for ($h= 0; $h -lt $argument.FieldCount; $h++) 
                    {
            $argumentsql = $argument.GetValue($h).ToString()
            foreach ($pcnimi in $argumentsql) {
            $pcnimi | Out-File  \\server\script\powershell\pc_list_temp.txt -append
        }
    }
}
$dbconnect.Close()
$read_list = cat \\server\script\powershell\pc_list_temp.txt       
$read_temp = cat \\server\script\powershell\pc_list.txt

foreach ($read_string in $read_temp) {
    if ($read_list -contains $read_string) {
    } else {
    "$read_string"
    }
}
(cat \\server\script\powershell\pc_list.txt | Measure-Object).Count
