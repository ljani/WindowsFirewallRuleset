
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $PSScriptRoot\DirectionSetup.ps1
. $PSScriptRoot\..\IPSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.Windows.UserInfo @Logs
Import-Module -Name $ProjectRoot\Modules\Project.Windows.ProgramInfo @Logs
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility @Logs

#
# Setup local variables:
#
$Group = "Store Apps"
$SystemGroup = "Store Apps - System"
$Profile = "Private, Public"
# $NetworkApps = Get-Content -Path "$PSScriptRoot\..\NetworkApps.txt"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $SystemGroup -Direction $Direction -ErrorAction Ignore @Logs

#
# Firewall predefined rules for Microsoft store Apps
#

#
# Block Administrators by default
#

New-NetFirewallRule -Platform $Platform `
	-DisplayName "Store apps for Administrators" -Service Any -Program Any `
	-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile Any -InterfaceType $Interface `
	-Direction $Direction -Protocol Any -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
	-EdgeTraversalPolicy Block -LocalUser Any -Owner (Get-GroupSID "Administrators") -Package "*" `
	-Description "Block admin activity for all store apps.
Administrators should have limited or no connectivity at all for maximum security." @Logs | Format-Output @Logs

#
# Create rules for all network apps for each standard user
#

$Principals = Get-GroupPrincipals "Users"
foreach ($Principal in $Principals)
{
	#
	# Create rules for apps installed by user
	#

	Get-AppxPackage -User $Principal.User -PackageTypeFilter Bundle | ForEach-Object {

		$PackageSID = Get-AppSID $Principal.User $_.PackageFamilyName
		$Enabled = "False"

		# if ($NetworkApps -contains $_.Name)
		# {
		#     $Enabled = "True"
		# }

		New-NetFirewallRule -Platform $Platform `
			-DisplayName $_.Name -Service Any -Program Any `
			-PolicyStore $PolicyStore -Enabled $Enabled -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
			-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort Any `
			-EdgeTraversalPolicy Block -LocalUser Any -Owner $Principal.SID -Package $PackageSID `
			-Description "Store apps generated rule." @Logs | Format-Output @Logs

		Update-Logs
	}

	#
	# Create rules for system apps
	#

	Get-AppxPackage -PackageTypeFilter Main | Where-Object { $_.SignatureKind -eq "System" -and $_.Name -like "Microsoft*" } | ForEach-Object {

		$PackageSID = Get-AppSID $Principal.User $_.PackageFamilyName
		$Enabled = "False"

		# if ($NetworkApps -contains $_.Name)
		# {
		#     $Enabled = "True"
		# }

		New-NetFirewallRule -Platform $Platform `
			-DisplayName $_.Name -Service Any -Program Any `
			-PolicyStore $PolicyStore -Enabled $Enabled -Action Allow -Group $SystemGroup -Profile $Profile -InterfaceType $Interface `
			-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort Any `
			-EdgeTraversalPolicy Block -LocalUser Any -Owner $Principal.SID -Package $PackageSID `
			-Description "System store apps generated rule." @Logs | Format-Output @Logs

		Update-Logs
	}
}

Update-Logs
