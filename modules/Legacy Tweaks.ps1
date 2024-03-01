<#
.SYNOPSIS
    This script runs all the autorun tweaks in the ../tweaks/autorun/ directory.
.PARAMETER UndoAll
    If this switch is present, the script will instead revert all the autorun tweaks (if a revert function or file is present).
#>

param (
    [Parameter(Position = 0, Mandatory = $false)] [switch] $UndoAll = $false
)

Get-ChildItem -Path "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\..\tweaks\autorun\" | ForEach-Object {
    $tweakUri = $_.FullName
    $extension = (Get-Item $tweakUri).Extension

    if ($extension -ne ".reg") {
        Write-Verbose "Found tweak $((Get-Item $tweakUri).BaseName)"
    }

    Switch ($extension) {
        ".ps1" { . "$tweakUri" -Undo:$script:UndoAll }
        ".cmd" { cmd /c `"$tweakUri`" /u $script:UndoAll }
        Default { Write-Host "Autorun file $_ is of an unkown type" }
    }
}
