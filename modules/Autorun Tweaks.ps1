<#
.SYNOPSIS
    This script runs all the autorun tweaks in the ../tweaks/autorun/ directory.
.PARAMETER UndoAll
    If this switch is present, the script will instead revert all the autorun tweaks (if a revert function or file is present).
#>

param (
    [Parameter(Position = 0, Mandatory = $false)] [switch] $UndoAll = $false
)

function runRegistryTweak {
    param (
        [Parameter(Position = 0, Mandatory = $true)] [string] $tweakUri
    )

    if ($script:UndoAll -and $tweakUri -like "*`(revert`)`.reg") {
        REG IMPORT `"$tweakUri`"
    }
    elseif (-not $script:UndoAll -and $tweakUri -notlike "*`(revert`)`.reg") {
        REG IMPORT `"$tweakUri`"
    }
}

Get-ChildItem -Path "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\..\tweaks\autorun\" | ForEach-Object {
    $tweakUri = $_.FullName
    $extension = (Get-Item $tweakUri).Extension

    Switch ($extension) {
        ".ps1" { . "$tweakUri" -Undo:$script:UndoAll }
        ".reg" { runRegistryTweak -tweakUri $tweakUri }
        ".cmd" { cmd /c `"$tweakUri`" /u $script:UndoAll }
        Default { Write-Host "Autorun file $_ is of an unkown type" }
    }
}
