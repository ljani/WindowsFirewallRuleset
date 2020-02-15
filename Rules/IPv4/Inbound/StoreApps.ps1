
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems,
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (c) 2019, 2020 metablaster zebal@protonmail.ch

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

. $PSScriptRoot\..\..\..\UnloadModules.ps1

# Check requirements for this project
Import-Module -Name $PSScriptRoot\..\..\..\Modules\System
Test-SystemRequirements

# Includes
. $PSScriptRoot\DirectionSetup.ps1
. $PSScriptRoot\..\IPSetup.ps1
Import-Module -Name $RepoDir\Modules\UserInfo
Import-Module -Name $RepoDir\Modules\ProgramInfo
Import-Module -Name $RepoDir\Modules\FirewallModule

#
# Setup local variables:
#
$Group = "Store Apps"
$SystemGroup = "Store Apps - System"
$Profile = "Private, Public"
# $NetworkApps = Get-Content -Path "$PSScriptRoot\..\NetworkApps.txt"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $SystemGroup -Direction $Direction -ErrorAction SilentlyContinue

#
# Firewall predefined rules for Microsoft store Apps
#

#
# Block Administrators by defalut
#

foreach ($Admin in $AdminNames)
{
	New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
	-DisplayName "Store apps for Administrators" -Service Any -Program Any `
	-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile Any -InterfaceType $Interface `
	-Direction $Direction -Protocol Any -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
	-EdgeTraversalPolicy Block -LocalUser Any -Owner (Get-UserSID $Admin) -Package "S-1-15-2-1" `
	-Description "Block admin activity for all store apps.
	Administrators should have limited or no connectivity at all for maximum security." | Format-Output
}

#
# Create rules for all network apps for each standard user
#

foreach ($User in $UserNames)
{
	$OwnerSID = Get-UserSID($User)

	#
	# Create rules for apps installed by user
	#

	Get-AppxPackage -User $User -PackageTypeFilter Bundle | ForEach-Object {

		$PackageSID = (Get-AppSID $User $_.PackageFamilyName)
		$Enabled = "False"

		# if ($NetworkApps -contains $_.Name)
		# {
		#     $Enabled = "True"
		# }

		New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
		-DisplayName $_.Name -Service Any -Program Any `
		-PolicyStore $PolicyStore -Enabled $Enabled -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort Any `
		-EdgeTraversalPolicy Block -LocalUser Any -Owner $OwnerSID -Package $PackageSID `
		-Description "Store apps generated rule." | Format-Output
	}

	#
	# Create rules for system apps
	#

	Get-AppxPackage -PackageTypeFilter Main | Where-Object { $_.SignatureKind -eq "System" -and $_.Name -like "Microsoft*" } | ForEach-Object {

		$PackageSID = (Get-AppSID $User $_.PackageFamilyName)
		$Enabled = "False"

		# if ($NetworkApps -contains $_.Name)
		# {
		#     $Enabled = "True"
		# }

		New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
		-DisplayName $_.Name -Service Any -Program Any `
		-PolicyStore $PolicyStore -Enabled $Enabled -Action Allow -Group $SystemGroup -Profile $Profile -InterfaceType $Interface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort Any `
		-EdgeTraversalPolicy Block -LocalUser Any -Owner $OwnerSID -Package $PackageSID `
		-Description "System store apps generated rule." | Format-Output
	}
}
