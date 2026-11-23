#define AppName "Animation Studio Master"
#define AppVersion "0.1.0"
#define AppPublisher "Animation Studio Master"

[Setup]
AppId={{B62B9D3E-3D5A-4A91-8C44-3C6A7B6C11F0}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\Animation Studio Master
DefaultGroupName={#AppName}
UninstallDisplayIcon={app}\AnimationStudioMaster.exe
OutputDir=..\build
OutputBaseFilename=AnimationStudioMaster-Setup-x64
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
DisableProgramGroupPage=yes
CloseApplications=yes
RestartApplications=no

[Tasks]
Name: "desktopicon"; Description: "Crear un acceso directo en el escritorio"; GroupDescription: "Accesos directos:"

[Files]
Source: "..\build\AnimationStudioMaster.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\AnimationStudioMaster.exe"; WorkingDir: "{app}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\AnimationStudioMaster.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\AnimationStudioMaster.exe"; Description: "Iniciar {#AppName}"; WorkingDir: "{app}"; Flags: nowait postinstall skipifsilent
