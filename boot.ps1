# Usage: iwr -useb https://enve.gamelab.tw/install.ps1 | iex

$wslActived = $false
$distFirstMatch = $null
$distBestMatch = $null
wsl -l -v |
    Where-Object {$_ -notmatch 'NAME'} |
    ForEach-Object {
        $Records = $_ -split '\s+'
        $isDefault = $Records[0]
        $name = $Records[1]
        $state = $Records[2]
        $version = $Records[3]

        $wslActived = $true
        if ($version -eq '2') {
            if ($distFirstMatch -eq $null) {
                $distFirstMatch = $name
            }
            if ($isDefault -eq '*') {
                $distBestMatch = $name
            }
        }
    }

if (!$wslActived) {
    wsl --install -n
    $distBestMatch = 'Ubuntu'
}
if (!$distBestMatch) {
    $distBestMatch = $distFirstMatch
}

if ($args[0]) {
    $path = wsl wslpath -a -u "$PSScriptRoot"
    wsl --distribution $distBestMatch sh -c "$path/bin/enve $args"
} else {
    wsl --distribution $distBestMatch sh -c 'curl https://enve.gamelab.tw/install | sh'
}

