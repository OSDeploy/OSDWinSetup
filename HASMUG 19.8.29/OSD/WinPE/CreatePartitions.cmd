cls
@echo off
if not exist X:\Windows\System32 echo ERROR: This script is built to run in Windows PE
if not exist X:\Windows\System32 goto END
::	https://msdn.microsoft.com/en-us/library/windows/hardware/dn293283.aspx
::	https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-deployment-sample-scripts-sxs
echo.
::	echo *********************************************************************
::	echo Setting high-performance power scheme to speed deployment...
::	call powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
echo *********************************************************************
echo Checking to see if the PC is booted in BIOS or UEFI mode...
wpeutil UpdateBootInfo
for /f "tokens=2* delims=	 " %%A in ('reg query HKLM\System\CurrentControlSet\Control /v PEFirmwareType') DO SET Firmware=%%B
:: Note: delims is a TAB followed by a space.
echo *********************************************************************
if %Firmware%==0x1 goto BIOS
if %Firmware%==0x2 goto UEFI
goto END

:BIOS
echo BIOS: Preparing MBR Drives...
echo The PC is booted in BIOS mode
echo select disk 0 >"%Temp%\CreatePartitions-BIOS.txt"
echo clean>>"%Temp%\CreatePartitions-BIOS.txt"
echo rem == 1. System partition =========================>>"%Temp%\CreatePartitions-BIOS.txt"
echo create partition primary size=984>>"%Temp%\CreatePartitions-BIOS.txt"
echo format quick fs=ntfs label="System">>"%Temp%\CreatePartitions-BIOS.txt"
echo assign letter="S">>"%Temp%\CreatePartitions-BIOS.txt"
echo active>>"%Temp%\CreatePartitions-BIOS.txt"
echo rem == 2. Windows partition ========================>>"%Temp%\CreatePartitions-BIOS.txt"
echo create partition primary>>"%Temp%\CreatePartitions-BIOS.txt"
echo format quick fs=ntfs label="OSDisk">>"%Temp%\CreatePartitions-BIOS.txt"
echo assign letter="C">>"%Temp%\CreatePartitions-BIOS.txt"
echo rem ================================================>>"%Temp%\CreatePartitions-BIOS.txt"
echo rescan>>"%Temp%\CreatePartitions-BIOS.txt"
echo list volume>>"%Temp%\CreatePartitions-BIOS.txt"
echo exit>>"%Temp%\CreatePartitions-BIOS.txt"

diskpart /s %Temp%\CreatePartitions-BIOS.txt
goto END

:UEFI
echo UEFI: Preparing GPT Drives...
echo select disk 0 >"%Temp%\CreatePartitions-UEFI.txt"
echo clean>>"%Temp%\CreatePartitions-UEFI.txt"
echo convert gpt>>"%Temp%\CreatePartitions-UEFI.txt"
echo rem == 1. System Partition =========================>>"%Temp%\CreatePartitions-UEFI.txt"
echo create partition efi size=200>>"%Temp%\CreatePartitions-UEFI.txt"
echo format quick fs=fat32 label="System">>"%Temp%\CreatePartitions-UEFI.txt"
echo assign letter=S>>"%Temp%\CreatePartitions-UEFI.txt"
echo rem == 2. Microsoft Reserved (MSR) Partition =======>>"%Temp%\CreatePartitions-UEFI.txt"
echo create partition msr size=128>>"%Temp%\CreatePartitions-UEFI.txt"
echo rem == 3. Windows Partition ========================>>"%Temp%\CreatePartitions-UEFI.txt"
echo create partition primary>>"%Temp%\CreatePartitions-UEFI.txt"
echo gpt attributes=0x0000000000000000>>"%Temp%\CreatePartitions-UEFI.txt"
echo format quick fs=ntfs label="OSDisk">>"%Temp%\CreatePartitions-UEFI.txt"
echo assign letter=C>>"%Temp%\CreatePartitions-UEFI.txt"
echo rem == 4. Recovery Partition =======================>>"%Temp%\CreatePartitions-UEFI.txt"
echo shrink minimum=984>>"%Temp%\CreatePartitions-UEFI.txt"
echo create partition primary>>"%Temp%\CreatePartitions-UEFI.txt"
echo set id=DE94BBA4-06D1-4D40-A16A-BFD50179D6AC>>"%Temp%\CreatePartitions-UEFI.txt"
echo gpt attributes=0x8000000000000001>>"%Temp%\CreatePartitions-UEFI.txt"
echo format quick fs=ntfs label="Recovery">>"%Temp%\CreatePartitions-UEFI.txt"
echo assign letter=R>>"%Temp%\CreatePartitions-UEFI.txt"
echo rem ================================================>>"%Temp%\CreatePartitions-UEFI.txt"
echo rescan>>"%Temp%\CreatePartitions-UEFI.txt"
echo list volume>>"%Temp%\CreatePartitions-UEFI.txt"
echo exit>>"%Temp%\CreatePartitions-UEFI.txt"

diskpart /s %Temp%\CreatePartitions-UEFI.txt
goto END

:END