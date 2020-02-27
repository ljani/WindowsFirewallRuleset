
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

Set-StrictMode -Version Latest

#
# Module preferences
#

if ($Develop)
{
	$ErrorActionPreference = $ModuleErrorPreference
	$WarningPreference = $ModuleWarningPreference
	$DebugPreference = $ModuleDebugPreference
	$VerbosePreference = $ModuleVerbosePreference
	$InformationPreference = $ModuleInformationPreference

	Set-Variable ThisModule -Scope Script -Option ReadOnly -Force -Value ($MyInvocation.MyCommand.Name -replace ".{5}$")

	Write-Debug -Message "[$ThisModule] ErrorActionPreference is $ErrorActionPreference"
	Write-Debug -Message "[$ThisModule] WarningPreference is $WarningPreference"
	Write-Debug -Message "[$ThisModule] DebugPreference is $DebugPreference"
	Write-Debug -Message "[$ThisModule] VerbosePreference is $VerbosePreference"
	Write-Debug -Message "[$ThisModule] InformationPreference is $InformationPreference"
}

# TODO: stream logging instead of open/close file for performance

<#
.SYNOPSIS
Generates a log file name for Update-Logs function
.DESCRIPTION
Generates a log file name composed of current date and time and appends to input
log level label and input path.
The function checks if a path to file exists, if not it creates one.
.PARAMETER Folder
Path to folder where to save logs
.PARAMETER FileLabel
File label which preceeds date an time, ie Warning or Error.
.EXAMPLE
Get-LogFile "C:\Logs" "Warning"
Warning_25.02.20 19h.log
.INPUTS
None. You cannot pipe objects to Get-LogFile
.OUTPUTS
[string] full path to log file
.NOTES
TODO: Maybe a separate folder for each day?
TODO: need to check if drive exists
#>
function Get-LogFile
{
	[OutputType([System.String])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $Folder,

		[Parameter(Mandatory = $true)]
		[string] $FileLabel
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# Generate file name
	$FileName = $FileLabel + "_$(Get-Date -Format "dd.MM.yy HH")h.log"
	$LogFile = Join-Path -Path $Folder -ChildPath $FileName

	# Create Logs directory if it doesn't exist
	if (!(Test-Path -PathType Container -Path $Folder))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating log directory $Folder"
		New-Item -ItemType Directory -Path $Folder -ErrorAction Stop | Out-Null
	}

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Logs folder is: $Folder"
	Write-Debug -Message "[$($MyInvocation.InvocationName)] Generate log file name: $FileName"

	return $LogFile
}

<#
.SYNOPSIS
Log and format errors, warnings and infos generated by advanced functions
.DESCRIPTION
Advanced functions are first given "@Logs" splating for 3 common parameter variables,
which are then filled with streams.
Update-Logs is called at some point afterwards in same scope and it reads error,
warning and information common variable stream records generated by advaned functions.
Update-Logs formats if needed and logs them into a file.
Error, Warning and info preferences and log switch can be overriden at any time and the Update-Logs will pick up
those values automatically since these 3 variables are local to script.
.EXAMPLE
Some-Function @Logs
Update-Logs
.EXAMPLE
Some-Function @Logs | Another-Function @Logs
Update-Logs
.INPUTS
None. You cannot pipe objects to Update-Logs
.OUTPUTS
None. Log files are writen to log directory.
#>
function Update-Logs
{
	[OutputType([System.Void])]
	[CmdletBinding()]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Checking if there is data to write logs"
	$ErrorBuffer = $PSCmdlet.GetVariableValue('ErrorBuffer')
	$WarningBuffer = $PSCmdlet.GetVariableValue('WarningBuffer')
	$InfoBuffer = $PSCmdlet.GetVariableValue('InfoBuffer')

	if ($ErrorBuffer)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing Error message"

		$Preference = $PSCmdlet.GetVariableValue('ErrorActionPreference')
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller ErrorActionPreference is: $Preference"

		if ($Preference -ne "SilentlyContinue")
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting error status variable"
			Set-Variable -Name ErrorStatus -Scope Global -Value $true
		}

		if ($ErrorLogging)
		{
			$LogFile = Get-LogFile $LogsFolder "Error"

			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Appending error to log file: $LogFile"
			$ErrorBuffer | ForEach-Object { $_ | Select-Object * | Out-File -Append -FilePath $LogFile }
		}

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Clearing errors buffer"
		$ErrorBuffer.Clear()
	}

	if ($WarningBuffer)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing Warning message"

		$Preference = $PSCmdlet.GetVariableValue('WarningPreference')
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller WarningPreference is: $Preference"

		if ($Preference -ne "SilentlyContinue")
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting warning status variable"
			Set-Variable -Name WarningStatus -Scope Global -Value $true
		}

		if ($WarningLogging)
		{
			$LogFile = Get-LogFile $LogsFolder "Warning"

			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Appending warnings to log file: $LogFile"

			# NOTE: we have to add the WARNING label, it's not included in the message by design
			$WarningBuffer | ForEach-Object { "WARNING: $(Get-Date -Format "HH:mm:ss") $_" | Out-File -Append -FilePath $LogFile }
		}

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Clearing warnings buffer"
		$WarningBuffer.Clear()
	}

	if ($InfoBuffer)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Processing Information message"

		if ($InformationLogging)
		{
			$LogFile = Get-LogFile $LogsFolder "Info"

			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Appending information to log file: $LogFile"
			$InfoBuffer | ForEach-Object { $_ | Select-Object * | Out-File -Append -FilePath $LogFile }
		}

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Clearing information buffer"
		$InfoBuffer.Clear()
	}
}

#
# Module variables
#

if (!(Get-Variable -Name CheckInitLogging -Scope Global -ErrorAction Ignore))
{
	Write-Debug -Message "[$ThisModule] Initialize global constant variable: CheckInitLogging"
	# check if constants alreay initialized, used for module reloading
	New-Variable -Name CheckInitLogging -Scope Global -Option Constant -Value $null

	Write-Debug -Message "[$ThisModule] Initialize global constant variable: Logs"
	# These defaults are for advanced functions to enable logging, do not modify!
	New-Variable -Name Logs -Scope Global -Option Constant -Value @{
		ErrorVariable = "+ErrorBuffer"
		WarningVariable = "+WarningBuffer"
		InformationVariable = "+InfoBuffer"
	}
}

# Folder where logs get saved
Write-Debug -Message "[$ThisModule] Initialize module constant variable: LogsFolder"
New-Variable -Name LogsFolder -Scope Script -Option Constant -Value ($ProjectRoot + "\Logs")

#
# Function exports
#

Export-ModuleMember -Function Update-Logs

#
# Variable exports
#

Export-ModuleMember -Variable CheckInitLogging
Export-ModuleMember -Variable Logs
Export-ModuleMember -Variable ErrorStatus
Export-ModuleMember -Variable WarningStatus
