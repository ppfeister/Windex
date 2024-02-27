# Windex
# https://github.com/ppfeister/windex
#
# MAINTAINER : Paul Pfeister ( https://github.com/ppfeister : https://pfeister.dev )
#            :
# PURPOSE    : Eliminate much of the crapware that comes with Windows 10 and Windows 11, and disable or otherwise
#            : mitigate certain baked-in telemetry items, to the greatest extent possible without breaking Windows.
#            :
# LICENSE    : GNU General Public License v3.0 : https://github.com/ppfeister/windex/blob/master/LICENSE

<#
.SYNOPSIS
Parse yaml tweak manifests and apply them to the system.
.PARAMETER PlaybookUri
The relative or absolute path to the YAML playbook.
.PARAMETER Category
The category of tweaks to display. If not specified, all tweaks will be displayed.
.LINK
Official repository: https://github.com/ppfeister/Windex
.LINK
Latest release: https://github.com/ppfeister/Windex/releases/latest
#>

#Requires -RunAsAdministrator

param (
    [Parameter(Position = 0, Mandatory = $true)] [string] $PlaybookUri,
    [Parameter(Position = 1, Mandatory = $true)] [string] $Category = "all"
)

# PLAYBOOK PARSER

$WindexRootUri = "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\..\.."

Get-ChildItem -Path "$WindexRootUri\modules\submodules\psyaml" -Recurse | Unblock-File
Import-Module -Name "$WindexRootUri\modules\submodules\psyaml\powershell-yaml.psd1" -Verbose:$false
$tweakPlaybook = Get-Content -Path "$WindexRootUri\defs\tweaks.yaml" -Raw 
$tweaksParsed = ConvertFrom-Yaml $tweakPlaybook
Remove-Module powershell-yaml -Verbose:$false


if ($Category -ne "all") {
    $tweaksParsed = $tweaksParsed | Where-Object { $_.Category -eq $Category }
}

# SELECTION MENU

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Windex : Tweak Selection'
$form.Size = New-Object System.Drawing.Size(400,300)
$form.StartPosition = 'CenterScreen'

$RunButton = New-Object System.Windows.Forms.Button
$RunButton.Location = New-Object System.Drawing.Point(125,230)
$RunButton.Size = New-Object System.Drawing.Size(150,23)
$RunButton.Text = 'Run Selected Tweaks'
$RunButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $RunButton
$form.Controls.Add($RunButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(350,40)
# (,$tweaksParsed) is used instead of simply $tweaksParsed to force treatment as a multidimensional array even when size == 1.
# Otherwise, when size == 1, .Count will count the number of elements in the first tweak instead of the number of tweaks.
$label.Text = "$((,$tweaksParsed).Count) tweaks found in playbook $([io.path]::GetFileNameWithoutExtension($PlaybookUri)) matching category $Category.`nSelect multiple by holding Ctrl."
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.Listbox
$listBox.Location = New-Object System.Drawing.Point(10,60)
$listBox.Size = New-Object System.Drawing.Size(350,20)

$listBox.SelectionMode = 'MultiExtended'

$tweaksParsed | ForEach-Object {
    [void] $listBox.Items.Add($_.Name)
}

$listBox.Height = 160
$form.Controls.Add($listBox)
$form.Topmost = $true

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $selectedTweaks = $listBox.SelectedItems
    return ,$selectedTweaks
}

return