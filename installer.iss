[Setup]
AppName=MedFlow
AppVersion=1.0.0
DefaultDirName={pf}\MedFlow
DefaultGroupName=MedFlow
OutputDir=installer
OutputBaseFilename=MedFlowSetup
Compression=lzma
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64

[Files]
Source: "build\windows\x64\runner\Release\*"; \
  DestDir: "{app}"; \
  Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{group}\MedFlow"; Filename: "{app}\smart_opd_kiosk_v2_vertical.exe"
Name: "{commondesktop}\MedFlow"; Filename: "{app}\smart_opd_kiosk_v2_vertical.exe"