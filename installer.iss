[Setup]
AppName=Smart OPD Kiosk
AppVersion=1.0.0
DefaultDirName={pf}\SmartOPDKiosk
DefaultGroupName=Smart OPD Kiosk
OutputDir=installer
OutputBaseFilename=SmartOPDKioskSetup
Compression=lzma
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64

[Files]
Source: "build\windows\x64\runner\Release\*"; \
  DestDir: "{app}"; \
  Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Smart OPD Kiosk"; Filename: "{app}\smart_opd_kiosk_v2_vertical.exe"
Name: "{commondesktop}\Smart OPD Kiosk"; Filename: "{app}\smart_opd_kiosk_v2_vertical.exe"
