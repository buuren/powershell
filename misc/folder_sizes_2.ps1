cls
$path = '\\fileserver\RD\RD_Department_Work\Projects\2012\EL.435311.023_AR_1_400_28,5\Product Documentation\Mechanical Drawings\Details\EL.745226.350_02_ugolok.pdf'
$shell = New-Object -COMObject Shell.Application
$folder = Split-Path $path
$file = Split-Path $path -Leaf
$shellfolder = $shell.Namespace($folder)
$shellfile = $shellfolder.ParseName($file)

0..287 | Foreach-Object { '{0} = {1}' -f $_, $shellfolder.GetDetailsOf($null, $_) }

$i = 0
do {
$shellfolder.GetDetailsOf($shellfile, $i)
$i++
}
while ($i -le 287)