# Get-FileHash shipped with PowerShell 4.0
#Requires -Version 4.0


[CmdletBinding(SupportsShouldProcess)]
[OutputType([Void])]
Param(
    [ValidateNotNullOrEmpty()]
    [String]$Path,
)

$PowerShellMin = New-Object -TypeName Version -ArgumentList 4, 0
if ($PSVersionTable.PSVersion -lt $PowerShellMin) {
    throw '{0} requires at least PowerShell {1}.' -f $MyInvocation.MyCommand.Name, $PowerShellMin
}

$PowerShellCore = New-Object -TypeName Version -ArgumentList 6, 0
if ($PSVersionTable.PSVersion -ge $PowerShellCore -and $PSVersionTable.Platform -ne 'Win32NT') {
    throw '{0} is only compatible with Windows.' -f $MyInvocation.MyCommand.Name
}

# Supported font extensions
$ValidExts = @('.otf', '.ttf')
$ValidExtsRegex = '\.(otf|ttf)$'

Function Get-Fonts {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    Param(
        [ValidateSet('System', 'User')]
        [String]$Scope = 'System'
    )

    switch ($Scope) {
        'System' {
            $FontsFolder = [Environment]::GetFolderPath('Fonts')
            $FontsRegKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
        }

        'User' {
            $FontsFolder = Join-Path -Path ([Environment]::GetFolderPath('LocalApplicationData')) -ChildPath 'Microsoft\Windows\Fonts'
            $FontsRegKey = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
        }
    }

    try {
        $FontFiles = @(Get-ChildItem -Path $FontsFolder -ErrorAction Stop | Where-Object Extension -In $ValidExts)
    } catch {
        throw 'Unable to enumerate {0} fonts folder: {1}' -f $Scope.ToLower(), $FontsFolder
    }

    try {
        $FontsReg = Get-Item -Path $FontsRegKey -ErrorAction Stop
    } catch {
        throw 'Unable to open {0} fonts registry key: {1}' -f $Scope.ToLower(), $FontsRegKey
    }

    $Fonts = New-Object -TypeName 'Collections.Generic.List[PSCustomObject]'
    $FontsRegFileNames = New-Object -TypeName 'Collections.Generic.List[String]'
    foreach ($FontRegName in ($FontsReg.Property | Sort-Object)) {
        $FontRegValue = $FontsReg.GetValue($FontRegName)

        if ($Scope -eq 'User') {
            $FontRegFileName = [IO.Path]::GetFileName($FontRegValue)
        } else {
            $FontRegFileName = $FontRegValue
        }

        if ($FontRegFileName -notmatch $ValidExtsRegex) {
            Write-Debug -Message ('Ignoring font with unsupported extension: {0} -> {1}' -f $FontRegName, $FontRegFileName)
            continue
        } elseif ($FontFiles.Name -notcontains $FontRegFileName) {
            Write-Warning -Message ('Font file for registered font does not exist: {0} -> {1}' -f $FontRegName, $FontRegFileName)
            continue
        }

        $Font = [PSCustomObject]@{
            Name = $FontRegName
            File = $FontFiles | Where-Object Name -EQ $FontRegFileName
        }

        $Fonts.Add($Font)
        $FontsRegFileNames.Add($FontRegFileName)
    }

    foreach ($FontFileName in $FontFiles.Name) {
        if ($FontFileName -notin $FontsRegFileNames) {
            Write-Warning -Message ('Font file not registered for {0}: {1}' -f $Scope.ToLower(), $FontFileName)
        }
    }

    return $Fonts.ToArray()
}


Function Install-FontShell {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([Void])]
    Param(
        [Parameter(Mandatory)]
        [Collections.Generic.List[IO.FileInfo]]$Fonts
    )

    Begin {
        # ShellSpecialFolderConstants enumeration
        # https://docs.microsoft.com/en-us/windows/desktop/api/Shldisp/ne-shldisp-shellspecialfolderconstants
        $ssfFONTS = 20

        # _SHFILEOPSTRUCTA structure
        # https://docs.microsoft.com/en-us/windows/desktop/api/shellapi/ns-shellapi-_shfileopstructa
        $FOF_SILENT = 4
        $FOF_NOCONFIRMATION = 16
        $FOF_NOERRORUI = 1024
        $FOF_NOCOPYSECURITYATTRIBS = 2048
        $CopyOptions = $FOF_SILENT + $FOF_NOCONFIRMATION + $FOF_NOERRORUI + $FOF_NOCOPYSECURITYATTRIBS

        $ShellApp = $null
        $FontsFolder = $null

        try {
            $ShellApp = New-Object -ComObject 'Shell.Application'
            $FontsFolder = $ShellApp.NameSpace($ssfFONTS)
        } catch {
            if ($ShellApp) { $null = [Runtime.InteropServices.Marshal]::ReleaseComObject($ShellApp) }
            throw $_
        }
    }

    Process {
        foreach ($Font in $Fonts) {
            if ($PSCmdlet.ShouldProcess($Font.Name, 'Install font via shell')) {
                Write-Verbose -Message ('Installing font via shell: {0}' -f $Font.Name)
                $FontsFolder.CopyHere($Font.FullName, $CopyOptions)
            }
        }
    }

    End {
        $null = [Runtime.InteropServices.Marshal]::ReleaseComObject($FontsFolder)
        $null = [Runtime.InteropServices.Marshal]::ReleaseComObject($ShellApp)
    }
}


# Use script location if no path provided
if (!$Path) {
    $Path = $PSScriptRoot
}

# Validate the source font path
try {
    $SourceFontPath = Get-Item -Path $Path -ErrorAction Stop
} catch {
    throw 'Provided path is invalid: {0}' -f $Path
}

# Enumerate fonts to be installed
if ($SourceFontPath -is [IO.DirectoryInfo]) {
    $SourceFonts = @(Get-ChildItem -Path $SourceFontPath | Where-Object Extension -In $ValidExts)

    if (!$SourceFonts) {
        throw 'Unable to locate any fonts in provided directory: {0}' -f $SourceFontPath
    }
} elseif ($SourceFontPath -is [IO.FileInfo]) {
    if ($SourceFontPath.Extension -notin $ValidExts) {
        throw 'Provided file does not appear to be a valid font: {0}' -f $SourceFontPath
    }

    $SourceFonts = @($SourceFontPath)
} else {
    throw 'Expected directory or file but received: {0}' -f $SourceFontPath.GetType().Name
}


# Retrieve installed fonts
$InstalledFonts = Get-Fonts -Scope 'User'

# Calculate the hash of each installed font
foreach ($Font in $InstalledFonts) {
    $FontHash = Get-FileHash -Path $Font.File.FullName
    $Font | Add-Member -MemberType NoteProperty -Name 'Hash' -Value $FontHash.Hash
}

# Filter out any already installed fonts
$InstallFonts = New-Object -TypeName 'Collections.Generic.List[IO.FileInfo]'
foreach ($Font in $SourceFonts) {
    $FontHash = Get-FileHash -Path $Font.FullName
    if ($FontHash.Hash -notin $InstalledFonts.Hash) {
        $InstallFonts.Add($Font)
    } else {
        Write-Verbose -Message ('Font is already installed: {0}' -f $Font.Name)
    }
}

# Install fonts using selected method
if ($InstallFonts) {
    Install-FontShell -Fonts $InstallFonts
}
