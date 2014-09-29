Когда наше файловое хранилище разменяло третий терабайт, все чаще наш отдел стал получать просьбы выяснить, кто удалил важный документ или целую папку с документами. Нередко это происходит по чьему-то злому умыслу. Бэкапы — это хорошо, но страна должна знать своих героев. А молоко вдвойне вкусней, когда мы можем написать его на PowerShell.

Пока разбирался, решил записать для коллег по цеху, а потом подумал, что может пригодиться кому-то еще. Материал получился смешанный. Кто-то найдет для себя готовое решение, кому-то пригодятся несколько неочевидные методы работы с PowerShell или планировщиком задач, а кто-то проверит на быстродействие свои скрипты.

В процессе поиска решения задачи прочитал статью за авторством Deks. Решил взять ее за основу, но некоторые моменты меня не устраивали.
Во-первых, время генерации отчета за четыре часа на 2-терабайтном хранилище, с которым одновременно работает около 200 человек, составило около пяти минут. И это притом, что лишнего у нас в логи не пишется. Это меньше, чем у Deks, но больше, чем хотелосю бы, потому что...
Во-вторых, все то же самое нужно было реализовать еще на двадцати серверах, гораздо менее производительных, чем основной.
В-третьих, вызывал вопросы график запуска генерации отчетов.
И в-четвертых, хотелось исключить себя из процесса доставки собранной информации конечным потребителям (читай: автоматизировать, чтобы мне с этим вопросом больше не звонили).

Но ход мыслей Deks мне понравился...

Краткий дискурс: При включенном аудите файловой системы в момент удаления файла в журнале безопасности создаются два события, с кодами 4663 и, следом, 4660. Первое записывает попытку запроса доступа на удаление, данные о пользователе и пути к удаляемому файлу, а второе — фиксирует свершившийся факт удаления. У событий есть уникальный идентификатор EventRecordID, который отличается на единицу у этих двух событий.

Ниже приведен исходный скрипт, собирающий информацию об удаленных файлах и пользователях, их удаливших.

$time =  (get-date) - (new-timespan -min 240)
$Events = Get-WinEvent -FilterHashtable @{LogName="Security";ID=4660;StartTime=$time} | Select TimeCreated,@{n="Запись";e={([xml]$_.ToXml()).Event.System.EventRecordID}} |sort Запись
$BodyL = ""
$TimeSpan = new-TimeSpan -sec 1
foreach($event in $events){
    $PrevEvent = $Event.Запись
    $PrevEvent = $PrevEvent - 1
    $TimeEvent = $Event.TimeCreated
    $TimeEventEnd = $TimeEvent+$TimeSpan
    $TimeEventStart = $TimeEvent- (new-timespan -sec 1)
    $Body = Get-WinEvent -FilterHashtable @{LogName="Security";ID=4663;StartTime=$TimeEventStart;EndTime=$TimeEventEnd} |where {([xml]$_.ToXml()).Event.System.EventRecordID -match "$PrevEvent"}|where{ ([xml]$_.ToXml()).Event.EventData.Data |where {$_.name -eq "ObjectName"}|where {($_.'#text') -notmatch ".*tmp"} |where {($_.'#text') -notmatch ".*~lock*"}|where {($_.'#text') -notmatch ".*~$*"}} |select TimeCreated, @{n="Файл_";e={([xml]$_.ToXml()).Event.EventData.Data | ? {$_.Name -eq "ObjectName"} | %{$_.'#text'}}},@{n="Пользователь_";e={([xml]$_.ToXml()).Event.EventData.Data | ? {$_.Name -eq "SubjectUserName"} | %{$_.'#text'}}} 
    if ($Body -match ".*Secret*"){
        $BodyL=$BodyL+$Body.TimeCreated+"`t"+$Body.Файл_+"`t"+$Body.Пользователь_+"`n"
    }
}
$Month = $Time.Month
$Year = $Time.Year
$name = "DeletedFiles-"+$Month+"-"+$Year+".txt"
$Outfile = "\serverServerLogFilesDeletedFilesLog"+$name
$BodyL | out-file $Outfile -append

С помощью команды Measure-Command получили следующее:

Measure-Command {
    ...
} | Select-Object TotalSeconds | Format-List

...
TotalSeconds : 313,6251476

Многовато, на вторичных ФС будет дольше. Сходу очень не понравился десятиэтажный пайп, поэтому для начала я его структурировал:

Get-WinEvent -FilterHashtable @{
    LogName="Security";ID=4663;StartTime=$TimeEventStart;EndTime=$TimeEventEnd
} `
    | Where-Object {([xml]$_.ToXml()).Event.System.EventRecordID -match "$PrevEvent"} `
    | Where-Object {([xml]$_.ToXml()).Event.EventData.Data  `
        | Where-Object {$_.name -eq "ObjectName"} `
        | Where-Object {($_.'#text') -notmatch ".*tmp"} `
        | Where-Object {($_.'#text') -notmatch ".*~lock*"} `
        | Where-Object {($_.'#text') -notmatch ".*~$*"}
    }
    | Select-Object TimeCreated,
        @{
            n="Файл_";
            e={([xml]$_.ToXml()).Event.EventData.Data `
                | Where-Object {$_.Name -eq "ObjectName"} `
                | ForEach-Object {$_.'#text'}
            }
        },
        @{
            n="Пользователь_";
            e={([xml]$_.ToXml()).Event.EventData.Data `
                | Where-Object {$_.Name -eq "SubjectUserName"} `
                | ForEach-Object {$_.'#text'}
            }
        }

Получилось уменьшить этажность пайпа и убрать перечисления Foreach, а заодно сделать код более читаемым, но большого эффекта это не дало, разница в пределах погрешности:

Measure-Command {
    $time =  (Get-Date) - (New-TimeSpan -min 240)
    $Events = Get-WinEvent -FilterHashtable @{LogName="Security";ID=4660;StartTime=$time}`
        | Select TimeCreated,@{n="EventID";e={([xml]$_.ToXml()).Event.System.EventRecordID}}`
        | Sort-Object EventID

    $DeletedFiles = @()
    $TimeSpan = new-TimeSpan -sec 1
    foreach($Event in $Events){
        $PrevEvent = $Event.EventID
        $PrevEvent = $PrevEvent - 1
        $TimeEvent = $Event.TimeCreated
        $TimeEventEnd = $TimeEvent+$TimeSpan
        $TimeEventStart = $TimeEvent- (New-TimeSpan -sec 1)
        $DeletedFiles += Get-WinEvent -FilterHashtable @{LogName="Security";ID=4663;StartTime=$TimeEventStart;EndTime=$TimeEventEnd} `
            | Where-Object {`
                ([xml]$_.ToXml()).Event.System.EventRecordID -match "$PrevEvent" `
                -and (([xml]$_.ToXml()).Event.EventData.Data `
                    | where {$_.name -eq "ObjectName"}).'#text' `
                        -notmatch ".*tmp$|.*~lock$|.*~$*"
            } `
            | Select-Object TimeCreated,
            @{n="FilePath";e={
                (([xml]$_.ToXml()).Event.EventData.Data `
                | Where-Object {$_.Name -eq "ObjectName"}).'#text'
                }
            },
            @{n="UserName";e={
                (([xml]$_.ToXml()).Event.EventData.Data `
                | Where-Object {$_.Name -eq "SubjectUserName"}).'#text'
                }
            } `
    }
} | Select-Object TotalSeconds | Format-List
$DeletedFiles | Format-Table UserName,FilePath -AutoSize

...
TotalSeconds : 302,6915627

Пришлось немного подумать головой. Какие операции занимают больше всего времени? Можно было бы натыкать еще десяток Measure-Command, но в общем-то в данном случае и так очевидно, что больше всего времени тратится на запросы в журнал (это не самая быстрая процедура даже в MMC) и на повторяющиеся конвертации в XML (к тому же, в случае с EventRecordID это и вовсе необязательно). Попробуем сделать и то и другое по одному разу, а заодно исключить промежуточные переменные:

Measure-Command {
    $time =  (Get-Date) - (New-TimeSpan -min 240)
    $Events = Get-WinEvent -FilterHashtable @{LogName="Security";ID=4660,4663;StartTime=$time}`
        | Select TimeCreated,ID,RecordID,@{n="EventXML";e={([xml]$_.ToXml()).Event.EventData.Data}}`
        | Sort-Object RecordID

    $DeletedFiles = @()
    foreach($Event in ($Events | Where-Object {$_.Id -EQ 4660})){
        $DeletedFiles += $Events `
        | Where-Object {`
            $_.Id -eq 4663 `
                -and $_.RecordID -eq ($Event.RecordID - 1) `
                -and ($_.EventXML | where Name -eq "ObjectName").'#text'`
                    -notmatch ".*tmp$|.*~lock$|.*~$"
        } `
        | Select-Object `
        @{n="RecordID";e={$Event.RecordID}}, TimeCreated,
        @{n="ObjectName";e={($_.EventXML | where Name -eq "ObjectName").'#text'}},
        @{n="UserName";e={($_.EventXML | where Name -eq "SubjectUserName").'#text'}}
    }
} | Select-Object TotalSeconds | Format-List
$DeletedFiles | Sort-Object UserName,TimeDeleted | Format-Table -AutoSize -HideTableHeaders

...
TotalSeconds : 167,7099384

А вот это уже результат. Ускорение практически в два раза!

Автоматизируем

Порадовались, и хватит. Три минуты — это лучше, чем пять, но как лучше всего запускать скрипт? Раз в час? Так могут ускользнуть записи, которые появляются одновременно с запуском скрипта. Делать запрос не за час, а за 65 минут? Тогда записи могут повторяться. Да и искать потом запись о нужном файле среди тысячи логов — мутор. Писать раз в сутки? Ротация логов забудет половину. Нужно что-то более надежное. В комментариях к статье Deks кто-то говорил о приложении на дотнете, работающем в режиме службы, но это, знаете, из разряда «There are 14 competing standards»…

В планировщике заданий Windows можно создать триггер на событие в системном журнале. Вот так:



Отлично! Скрипт будет запускаться ровно в момент удаления файла, и наш журнал будет создаватья в реальном времени! Но наша радость будет неполной, если мы не сможем определить, какое событие нам нужно записать в момент запуска. Нам нужна хитрость. Их есть у нас! Недолгий гуглинг показал, что по триггеру «Событие» планировщик может передавать исполняемому файлу информацию о событии. Но делается это, мягко говоря, неочевидно. Последовательность действий такая:

Создать задачу с триггером типа «Event»;
Экспортировать задачу в формат XML (через консоль MMC);
Добавить в ветку «EventTrigger» новую ветвь «ValueQueries» с элементами, описывающими переменные:

    <EventTrigger>
        ...
        <ValueQueries>
            <Value name="eventRecordID">Event/System/EventRecordID</Value>
        </ValueQueries>
    </EventTrigger>

где «eventRecordID» — название переменной, которую можно будет передать скрипту, а «Event/System/EventRecordID» — элемент схемы журнала Windows, с которой можно ознакомиться по ссылке внизу статьи. В данном случае это элемент с уникальным номером события.
Импортировать задание обратно в планировщик.

Но мы же не хотим натыкивать все это мышкой на 20 серверах, верно? Нужно автоматизировать. К сожалению, PowerShell не всесилен, и командлет New-ScheduledTaskTrigger пока что не умеет создавать триггеры типа Event. Поэтому применим чит-код и создадим задачу через COM-объект (пока что достаточно часто приходится прибегать к COM, хотя штатные командлеты умеют все больше и больше c каждой новой версией PS):

$scheduler = New-Object -ComObject "Schedule.Service"
$scheduler.Connect("localhost")
$rootFolder = $scheduler.GetFolder("\")
$taskDefinition = $scheduler.NewTask(0)

Нужно обязательно разрешить одновременный запуск нескольких экземпляров, а также, как мне кажется, стоит запретить ручной запуск и задать лимит времени выполнения:

$taskDefinition.Settings.Enabled = $True
$taskDefinition.Settings.Hidden = $False
$taskDefinition.Principal.RunLevel = 0 # 0 - обычные привилегии, 1 - повышенные привилегии
$taskDefinition.Settings.MultipleInstances = $True
$taskDefinition.Settings.AllowDemandStart = $False
$taskDefinition.Settings.ExecutionTimeLimit = "PT5M"

Создадим триггер типа 0 (Event). Далее задаем XML-запрос для получения нужных нам событий. Код XML-запроса можно получить в консоли MMC «Журнал событий», выбрав необходимые параметры и переключившись на вкладку «XML»:



$Trigger = $taskDefinition.Triggers.Create(0)
$Trigger.Subscription = '<QueryList>
    <Query Id="0" Path="Security">
        <Select Path="Security">
            *[System[Provider[@Name="Microsoft-Windows-Security-Auditing"] and EventID=4660]]
        </Select>
    </Query>
</QueryList>'

Главная хитрость: указываем переменную, которую нужно передать скрипту. 

$Trigger.ValueQueries.Create("eventRecordID", "Event/System/EventRecordID")

Собственно, описание выполняемой команды:

$Action = $taskDefinition.Actions.Create(0)
$Action.Path = 'PowerShell.exe'
$Action.WorkingDirectory = 'C:\Temp'
$Action.Arguments = '.\ParseDeleted.ps1 $(eventRecordID) C:\Temp\DeletionLog.log'

И — взлетаем!

$rootFolder.RegisterTaskDefinition("Log Deleted Files", $taskDefinition, 6, 'SYSTEM', $null, 5)

«Концепция поменялась»

Вернемся к скрипту для записи логов. Теперь нам не надо получать все события, а нужно доставать одно-единственное, да еще переданное в качестве аргумента. Для этого мы допишем заголовки, превращающие скрипт в командлет с параметрами. До кучи — сделаем возможным изменять путь к логу «на лету», авось, пригодится:

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position=1)]$RecordID,
  [Parameter(Mandatory=$False,Position=2)]$LogPath = "C:\DeletedFiles.log"
)

Дальше возникает нюанс: до сего момента мы получали события командлетом Get-WinEvent и фильтровали параметром -FilterHashtable. Он понимает ограниченный набор атрибутов, в который не входит EventRecordID. Поэтому фильтровать мы будем через параметр -FilterXml, мы же теперь и это умеем!

$XmlQuery="<QueryList>
  <Query Id='0' Path='Security'>
    <Select Path='Security'>*[System[(EventID=4663) and (EventRecordID=$($RecordID - 1))]]</Select>
  </Query>
</QueryList>"
$Event = Get-WinEvent -FilterXml $XmlQuery `
    | Select TimeCreated,ID,RecordID,@{n="EventXML";e={([xml]$_.ToXml()).Event.EventData.Data}}`

Теперь нам больше не нужно перечисление Foreach-Object, поскольку обрабатывается всего одно событие. Не два, потому что событие с кодом 4660 используется только для того, чтобы инициировать скрипт, полезной информации оно в себе не несет.
Помните, в начале я хотел, чтобы пользователи могли без моего участия узнатьзлодея? Так вот, в случае, если файл удален в папке документов какого-либо отдела — пишем лог также в корень папки отдела.

$EventLine = ""
if (($Event.EventXML | where Name -eq "ObjectName").'#text' -notmatch ".*tmp$|.*~lock$|.*~$"){
    $EventLine += "$($Event.TimeCreated)`t"
    $EventLine += "$($Event.RecordID)`t"
    $EventLine += ($Event.EventXML | where Name -eq "SubjectUserName").'#text' + "`t"
    $EventLine += ($ObjectName = ($Event.EventXML | where Name -eq "ObjectName").'#text')
    if ($ObjectName -match "Documents\Подразделения"){
        $OULogPath = $ObjectName `
            -replace "(.*Documents\\Подразделения\\[^\\]*\\)(.*)",'$1\DeletedFiles.log'
        if (!(Test-Path $OULogPath)){
            "DeletionDate`tEventID`tUserName`tObjectPath"| Out-File -FilePath $OULogPath
        }
        $EventLine | Out-File -FilePath $OULogPath -Append
    }
    if (!(Test-Path $LogPath)){
        "DeletionDate`tEventID`tUserName`tObjectPath" | Out-File -FilePath $LogPath }
    $EventLine | Out-File -FilePath $LogPath -Append
}

Итоговый командлет

Ну вот, кусочки нарезаны, осталось собрать все воедино и еще чуть-чуть оптимизировать. Получится как-то так:

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position=1,ParameterSetName='logEvent')][int]$RecordID,
  [Parameter(Mandatory=$False,Position=2,ParameterSetName='logEvent')]
    [string]$LogPath = "$PSScriptRoot\DeletedFiles.log",
  [Parameter(ParameterSetName='install')][switch]$Install
)
if ($Install) {
    $service = New-Object -ComObject "Schedule.Service"
    $service.Connect("localhost")
    $rootFolder = $service.GetFolder("\")
    $taskDefinition = $service.NewTask(0)
    $taskDefinition.Settings.Enabled = $True
    $taskDefinition.Settings.Hidden = $False
    $taskDefinition.Settings.MultipleInstances = $True
    $taskDefinition.Settings.AllowDemandStart = $False
    $taskDefinition.Settings.ExecutionTimeLimit = "PT5M"
    $taskDefinition.Principal.RunLevel = 0
    $trigger = $taskDefinition.Triggers.Create(0)
    $trigger.Subscription = '
    <QueryList>
        <Query Id="0" Path="Security">
            <Select Path="Security">
                *[System[Provider[@Name="Microsoft-Windows-Security-Auditing"] and EventID=4660]]
            </Select>
        </Query>
    </QueryList>'
    $trigger.ValueQueries.Create("eventRecordID", "Event/System/EventRecordID")
    $Action = $taskDefinition.Actions.Create(0)
    $Action.Path = 'PowerShell.exe'
    $Action.WorkingDirectory = $PSScriptRoot
    $Action.Arguments = '.\' + $MyInvocation.MyCommand.Name + ' $(eventRecordID) ' + $LogPath
    $rootFolder.RegisterTaskDefinition("Log Deleted Files", $taskDefinition, 6, 'SYSTEM', $null, 5)
} else {
    $XmlQuery="<QueryList>
      <Query Id='0' Path='Security'>
        <Select Path='Security'>*[System[(EventID=4663) and (EventRecordID=$($RecordID - 1))]]</Select>
      </Query>
    </QueryList>"
    $Event = Get-WinEvent -FilterXml $XmlQuery `
        | Select TimeCreated,ID,RecordID,@{n="EventXML";e={([xml]$_.ToXml()).Event.EventData.Data}}`
    if (($ObjectName = ($Event.EventXML | where Name -eq "ObjectName").'#text') `
        -notmatch ".*tmp$|.*~lock$|.*~$"){
        $EventLine = "$($Event.TimeCreated)`t" + "$($Event.RecordID)`t" `
        + ($Event.EventXML | where Name -eq "SubjectUserName").'#text' + "`t" `
        + $ObjectName
        if ($ObjectName -match ".*Documents\\Подразделения\\[^\\]*\\"){
            $OULogPath = $Matches[0] + '\DeletedFiles.log'
            if (!(Test-Path $OULogPath)){
                "DeletionDate`tEventID`tUserName`tObjectPath"| Out-File -FilePath $OULogPath
            }
            $EventLine | Out-File -FilePath $OULogPath -Append
        }
        if (!(Test-Path $LogPath)){
            "DeletionDate`tEventID`tUserName`tObjectPath" | Out-File -FilePath $LogPath }
        $EventLine | Out-File -FilePath $LogPath -Append
    }
}

Осталось поместить скрипт в удобное для вас место и запустить с ключом -Install.

Теперь сотрудники любого отдела могут в реальном времени видеть, кто, что и когда удалил из их каталогов. Отмечу, что я не стал рассматривать здесь права доступа к файлам логов (чтобы злодей не мог их удалить) и ротацию. Структура и права доступа к каталогам на нашем файлере тянут на отдельную статью, а ротация в какой-то степени усложнит поиск нужной строки.
