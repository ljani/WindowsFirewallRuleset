
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

# TODO: Include modules you need, update licence Copyright and start writing test code

#
# Unit test for Test-Function
#
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Test @Logs
# Import-Module -Name $ProjectRoot\Modules\Project.Windows.UserInfo @Logs
# Import-Module -Name $ProjectRoot\Modules\Project.Windows.ProgramInfo @Logs
# Import-Module -Name $ProjectRoot\Modules\Project.Windows.ComputerInfo @Logs
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility @Logs

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$") @Logs
if (!(Approve-Execute @Logs)) { exit }

<#
.SYNOPSIS
A brief description of the function or script.
This keyword can be used only once in each topic.
.DESCRIPTION
A detailed description of the function or script.
This keyword can be used only once in each topic.
.PARAMETER Param
The description of a parameter. Add a ".PARAMETER" keyword for each parameter
in the function or script syntax.
.EXAMPLE
A sample command that uses the function or script,
optionally followed by sample output and a description. Repeat this keyword for each example.
.INPUTS
The Microsoft .NET Framework types of objects that can be piped to the function or script.
You can also include a description of the input objects.
.OUTPUTS
The .NET Framework type of the objects that the cmdlet returns.
You can also include a description of the returned objects.
.NOTES
Additional information about the function or script.
.LINK
The name of a related topic. The value appears on the line below the ".LINK" keyword and must
be preceded by a comment symbol # or included in the comment block.
.COMPONENT
The technology or feature that the function or script uses, or to which it is related.
This content appears when the Get-Help command includes the Component parameter of Get-Help.
.ROLE
The user role for the help topic. This content appears when the Get-Help command includes
the Role parameter of Get-Help.
.FUNCTIONALITY
The intended use of the function. This content appears when the Get-Help command includes
the Functionality parameter of Get-Help.
#>
function Test-Function
{
	param (
		[Parameter(Mandatory = $true)]
		[string] $Param
	)
}

Start-Test

New-Test "Test-Function"
Test-Function

Update-Logs
Exit-Test
