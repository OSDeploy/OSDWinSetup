Clear-Host
Write-Host "OSDWinSetup: Start Pre-Windows Setup ..." -ForegroundColor Cyan

$OSDWinSetupPhase = 'Unknown'
$OSDWinSetupEnvironment = 'Unknown'

if (Test-Path 'HKLM:\SYSTEM\Setup') {
    $SystemSetup = Get-ItemProperty -Path 'HKLM:\SYSTEM\Setup'
    #$SystemSetup
    # Determine if we are running Windows Setup
    if ($SystemSetup.SystemSetupInProgress -eq 0) {$OSDWinSetupPhase = 'Applications'}
    if ($SystemSetup.FactoryPreInstallInProgress -eq 1) {$OSDWinSetupPhase = 'WindowsPE'}
    if ($SystemSetup.SetupPhase -eq 4) {$OSDWinSetupPhase = 'Specialize'}
    #if ($SystemSetup.OOBEInProgress -eq 1) {$OSDWinSetupPhase = 'oobeSystem'}
    if ($SystemSetup.WorkingDirectory -like "X:\*") {$OSDWinSetupEnvironment = 'WinPE'}
    else {$OSDWinSetupEnvironment = 'Windows'}

    #$OSDWinSetupPhase
    #$OSDWinSetupEnvironment
} else {
    Write-Warning "OSDWinSetup: Could not get Setup information from the Registry ... Exiting!"
    Break
}

if ($OSDWinSetupPhase -eq 'WindowsPE') {
    #[void](Read-Host 'Press Enter to continue')
    #======================================================================================
    #	Set PowerShell Execution Policy
    #======================================================================================
    Write-Host "OSDWinSetup: Set PowerShell Execution Policy ..." -ForegroundColor Cyan
    Set-ExecutionPolicy Bypass
    #======================================================================================
    #	Adjust Power Plan
    #======================================================================================
    Write-Host "OSDWinSetup: Set High-Performance Power Scheme ..." -ForegroundColor Cyan
    Start-Process -FilePath powercfg -ArgumentList ('/s','8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c') -Wait
    #======================================================================================
    #	Increase the Screen Buffer size
    #======================================================================================
    if (!(Test-Path "HKCU:\Console")) {
        New-Item -Path "HKCU:\Console" -Force | Out-Null
        New-ItemProperty -Path HKCU:\Console ScreenBufferSize -Value 589889656 -PropertyType DWORD -Force | Out-Null
    }
    #======================================================================================
    #	Enable Network Support
    #======================================================================================
    Write-Host "OSDWinSetup: Enable Network Support ..." -ForegroundColor Cyan
    Start-Process -FilePath wpeinit -ArgumentList 'InitializeNetwork' -Wait
    Start-Sleep -Seconds 10
    #======================================================================================
    #	Renew IP Address
    #======================================================================================
    Write-Host "OSDWinSetup: Renew IP Address ..." -ForegroundColor Cyan
    Start-Process -FilePath ipconfig -ArgumentList '/Renew' -Wait
    #======================================================================================
    #	Start MSDaRT Remote Recovery
    #======================================================================================
    if (Test-Path 'X:\Windows\System32\RemoteRecovery.exe'){
        Write-Host "OSDWinSetup: Start MSDaRT Remote Recovery ..." -ForegroundColor Cyan
        Start-Process -FilePath RemoteRecovery -ArgumentList '-nomessage' -WindowStyle Minimized
    }
    #======================================================================================
    #	Start Dell UpdateBIOS
    #======================================================================================
    if ((Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer -like "*Dell*") {
		if (Test-Path "$PSScriptRoot\UpdateBIOS\Dell\Update-DellBios.ps1") {
			Write-Host "OSDWinSetup: Start Dell UpdateBIOS ..." -ForegroundColor Cyan
			Invoke-Expression -Command "$PSScriptRoot\UpdateBIOS\Dell\Update-DellBios.ps1"
			Clear-Host
		}
	}
    #======================================================================================
    #	Start Partition Script
    #======================================================================================
    if (Test-Path "$PSScriptRoot\WinPE\CreatePartitions.cmd") {
        Write-Host "OSDWinSetup: Start Partition Script ..." -ForegroundColor Cyan
        Write-Warning "If you continue, the Hard Drive will be CLEANED, PARTITIONED and FORMATTED"
        Write-Warning "ALL EXISTING DATA WILL BE LOST"
        [void](Read-Host 'Press Enter to continue')
        Start-Process -FilePath $Env:ComSpec -ArgumentList ('/c',"$PSScriptRoot\WinPE\CreatePartitions.cmd") -Wait
    }
    #======================================================================================
    #	Start OSDDrivers
    #======================================================================================
    if (Test-Path "$PSScriptRoot\OSDDrivers\Deploy-OSDDrivers.ps1") {
        Write-Host "OSDWinSetup: Start OSDDrivers ..." -ForegroundColor Cyan
        Invoke-Expression -Command "$PSScriptRoot\OSDDrivers\Deploy-OSDDrivers.ps1"
    }
    #======================================================================================
    #	Start Windows Setup
    #======================================================================================
    Write-Host "OSDWinSetup: Start Windows Setup ..." -ForegroundColor Cyan
    Read-Host -Prompt "Press Enter to Continue"
    Start-Sleep -Seconds 5
    Return
}

if ($OSDWinSetupPhase -eq 'Specialize') {
    #======================================================================================
    #	Set Power Plan
    #======================================================================================
    Write-Host "OSDWinSetup: Set High-Performance Power Scheme ..." -ForegroundColor Cyan
    Start-Process -FilePath powercfg -ArgumentList ('/s','8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c') -Wait
    #======================================================================================
    #	Increase the Screen Buffer size
    #======================================================================================
    if (!(Test-Path "HKCU:\Console")) {
        Write-Host "OSDWinSetup: Increase Console Screen Buffer Size ..." -ForegroundColor Cyan
        New-Item -Path "HKCU:\Console" -Force | Out-Null
        New-ItemProperty -Path HKCU:\Console ScreenBufferSize -Value 589889656 -PropertyType DWORD -Force | Out-Null
    }
    #======================================================================================
    #	Disable System Setup in Progress
    #   Resolves issue for WMI Queries
    #======================================================================================
    if (Test-Path -Path 'HKLM:\SYSTEM\Setup') {
        if ((Get-ItemProperty -Path 'HKLM:\SYSTEM\Setup').SystemSetupInProgress -eq 1) {
            Write-Host "OSDWinSetup: Disable System Setup in Progess ..." -ForegroundColor Cyan
            Set-ItemProperty -Path "HKLM:\SYSTEM\Setup" -Name "SystemSetupInProgress" -Value 0 -Force | Out-Null
        }
    }
    #======================================================================================
    #	Copy OSConfig
    #======================================================================================
    if (Test-Path -Path "$PSScriptRoot\OSConfig") {
        Write-Host "OSDWinSetup: Copy OSConfig ..." -ForegroundColor Cyan
        Copy-Item -Path "$PSScriptRoot\OSConfig" -Destination $env:ProgramData\OSConfig -Recurse -Verbose
    }
    #======================================================================================
    #	Start OSConfig
    #======================================================================================
    if (Test-Path -Path "$env:ProgramData\OSConfig") {
        Write-Host "OSDWinSetup: Start OSConfig ..." -ForegroundColor Cyan
        Invoke-Expression -Command "$env:ProgramData\OSConfig\OSConfig.ps1"
    }
    #======================================================================================
    #	Rename Computer to Serial Number
    #======================================================================================
    $Serial = Get-CimInstance -Class "Win32_BIOS" | Select-Object -Expand SerialNumber
    $Serial = $Serial.Replace(' ','').Replace('-','').Replace('.','')
    $Serial = $Serial.Substring(0, [System.Math]::Min(12, $Serial.Length))
    $NewName = "$Serial"
    if (!(Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\Microsoft-Windows-Shell-Setup')) {
        New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\Microsoft-Windows-Shell-Setup' -Force
    }
    Write-Host "OSDWinSetup: Renaming Computer to $NewName ..." -ForegroundColor Cyan
    Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\Microsoft-Windows-Shell-Setup' -Name 'ComputerName' -Value $NewName -Force
    #======================================================================================
    #	Tweaks
    #======================================================================================
    Write-Host "OSDWinSetup: Enable Local Administrator Account ..." -ForegroundColor Cyan
    cmd /c net user Administrator /active:yes
    #======================================================================================
    Write-Host "OSDWinSetup: Enable Admin Shares ..." -ForegroundColor Cyan
    reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v FilterAdministratorToken /t REG_DWORD /d 0 /f
    #======================================================================================
    Write-Host "OSDWinSetup: Disable User Account Page ..." -ForegroundColor Cyan
    reg add HKLM\Software\Microsoft\Windows\CurrentVersion\Setup\OOBE /v UnattendCreatedUser /t REG_DWORD /d 1 /f
    #======================================================================================
    Write-Host "OSDWinSetup: Disable Async RunOnce ..." -ForegroundColor Cyan
    reg add HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer /v AsyncRunOnce /t REG_DWORD /d 0 /f
    reg add HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System /v DelayedDesktopSwitchTimeout /t REG_DWORD /d 0 /f
    #======================================================================================
    Write-Host "OSDWinSetup: Disable Cortana Voice ..." -ForegroundColor Cyan
    if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE\DisableVoice') {
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" -Name "DisableVoice" -Force -ErrorAction SilentlyContinue
    }
    #======================================================================================
    Write-Host "OSDWinSetup: Enable System Setup in Progress to enable WMI Queries ..." -ForegroundColor Cyan
    if (Test-Path -Path 'HKLM:\SYSTEM\Setup') {
        if ((Get-ItemProperty -Path 'HKLM:\SYSTEM\Setup').SystemSetupInProgress -eq 0) {
            Set-ItemProperty -Path "HKLM:\SYSTEM\Setup" -Name "SystemSetupInProgress" -Value 1 -Force | Out-Null
        }
    }
    #======================================================================================
	#Read-Host -Prompt "Press Enter to Continue"
    #======================================================================================
}
if ($OSDWinSetupPhase -eq 'Applications') {
    #======================================================================================
    #	Adjust Power Plan
    #======================================================================================
    Write-Host "OSDWinSetup: Set High-Performance Power Scheme ..." -ForegroundColor Cyan
    Start-Process -FilePath powercfg -ArgumentList ('/s','8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c') -Wait
    #======================================================================================
    #	Reset Administrator Password to Serial Number
    #======================================================================================
	Write-Host "OSDWinSetup: Resetting Administrator Password ..." -ForegroundColor Cyan
	cmd /c net user Administrator $Serial
    #==============================================================================================================================================
    Write-Host "OSDWinSetup: Workgroup Setup Complete! ..." -ForegroundColor Green
    Write-Host "If you need to join this computer to the Domain, contact the Help Desk"
	#Read-Host -Prompt "Press Enter to Continue"
}
#======================================================================================
#Start-Process PowerShell_ISE.exe -Wait
#Read-Host -Prompt "Press Enter to Continue"