
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
$Group = "Wireless Networking"
$WNInterface = "Wireless"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Windows system predefined rules for Wireless Display
#

# NOTE: several rules down use this path
$WUDFHost = "%SystemRoot%\System32\WUDFHost.exe"
Test-File $WUDFHost

# TODO: local user may need to be 'Any', needs testing.
New-NetFirewallRule -DisplayName "Wireless Display" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service Any -Program $WUDFHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort 443 `
	-LocalUser $NT_AUTHORITY_UserModeDrivers `
	-InterfaceType $WNInterface `
	-Description "Driver Foundation - User-mode Driver Framework Host Process.
The driver host process (Wudfhost.exe) is a child process of the driver manager service.
loads one or more UMDF driver DLLs, in addition to the framework DLLs." `
	@Logs | Format-Output @Logs

# TODO: remote port unknown, rule added because predefined rule for UDP exists
New-NetFirewallRule -DisplayName "Wireless Display" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service Any -Program $WUDFHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser $NT_AUTHORITY_UserModeDrivers `
	-InterfaceType $WNInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Driver Foundation - User-mode Driver Framework Host Process.
The driver host process (Wudfhost.exe) is a child process of the driver manager service.
loads one or more UMDF driver DLLs, in addition to the framework DLLs." `
	@Logs | Format-Output @Logs

#
# Windows system predefined rules for WiFi Direct
#

New-NetFirewallRule -DisplayName "WLAN Service WFD ASP Coordination Protocol" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service WlanSvc -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort 7325 -RemotePort 7325 `
	-LocalUser Any `
	-InterfaceType $WNInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "WLAN Service to allow coordination protocol for WFD Service sessions.
Wi-Fi Direct (WFD) Protocol Specifies: Proximity Extensions, which enable two or more devices that
are running the same application to establish a direct connection without requiring an intermediary,
such as an infrastructure wireless access point (WAP).
For more info see description of WLAN AutoConfig service." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "WLAN Service WFD Driver-only" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $NT_AUTHORITY_System `
	-InterfaceType $WNInterface `
	-Description "Rule for drivers to communicate over WFD, WFD Services kernel mode driver rule.
Wi-Fi Direct (WFD) Protocol Specifies: Proximity Extensions, which enable two or more devices that
are running the same application to establish a direct connection without requiring an intermediary,
such as an infrastructure wireless access point (WAP).
For more info see description of WLAN AutoConfig service." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "WLAN Service WFD Driver-only" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $NT_AUTHORITY_System `
	-InterfaceType $WNInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for drivers to communicate over WFD, WFD Services kernel mode driver rule.
Wi-Fi Direct (WFD) Protocol Specifies: Proximity Extensions, which enable two or more devices that
are running the same application to establish a direct connection without requiring an intermediary,
such as an infrastructure wireless access point (WAP).
For more info see description of WLAN AutoConfig service." `
	@Logs | Format-Output @Logs

#
# Windows system predefined rules for WiFi Direct Network Discovery
#

$Program = "%SystemRoot%\System32\dasHost.exe"
Test-File $Program @Logs

# TODO: missing protocol and port for WiFi Direct Network Discovery
New-NetFirewallRule -DisplayName "Wi-Fi Direct Network Discovery" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol Any `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $NT_AUTHORITY_LocalService `
	-InterfaceType Wired, Wireless `
	-Description "Rule to discover WSD devices on Wi-Fi Direct networks.
Host enables pairing between the system and wired or wireless devices.
This service is new since Windows 8.
Executable also known as Device Association Framework Provider Host." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Wi-Fi Direct Scan Service" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service stisvc -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol Any `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType Wired, Wireless `
	-Description "Rule to use WSD scanners on Wi-Fi Direct networks.
Windows Image Acquisition (WIA) service provides image acquisition services for scanners
and cameras." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Wi-Fi Direct Spooler Use" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Spooler -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol Any `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType Wired, Wireless `
	-Description "Rule to use WSD printers on Wi-Fi Direct networks.
Print Spooler service spools print jobs and handles interaction with the printer.
If you turn off this service, you won't be able to print or see your printers." `
	@Logs | Format-Output @Logs

#
# Windows system predefined rules for Wireless portable devices
#

New-NetFirewallRule -DisplayName "Wireless portable devices (SSDP)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
	-Service SSDPSRV -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort 1900 `
	-LocalUser Any `
	-InterfaceType $WNInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Wireless Portable Devices to allow use of the
Simple Service Discovery Protocol." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Wireless portable devices" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Public `
	-Service Any -Program $WUDFHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort 15740 `
	-LocalUser Any `
	-InterfaceType $WNInterface `
	-Description "Wireless Portable Devices to allow use of the Usermode Driver Framework." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Wireless portable devices" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Domain `
	-Service Any -Program $WUDFHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Intranet4 `
	-LocalPort Any -RemotePort 15740 `
	-LocalUser Any `
	-InterfaceType $WNInterface `
	-Description "Wireless Portable Devices to allow use of the Usermode Driver Framework." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Wireless portable devices (UPnPHost)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
	-Service upnphost -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort 2869 `
	-LocalUser Any `
	-InterfaceType $WNInterface `
	-Description "Wireless Portable Devices to allow use of Universal Plug and Play." `
	@Logs | Format-Output @Logs

# TODO: possible bug in predefined rule, description is not consistent with service parameter
New-NetFirewallRule -DisplayName "Wireless portable devices (FDPHost)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
	-Service fdphost -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort 2869 `
	-LocalUser Any `
	-InterfaceType $WNInterface `
	-Description "Wireless Portable Devices to allow use of Function discovery provider host." `
	@Logs | Format-Output @Logs

Update-Logs
