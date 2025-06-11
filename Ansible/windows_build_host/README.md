# Windows build host for MediaArea projects

## Ansible requirements
- Windows 10/11 with WinRM enabled (see https://learn.microsoft.com/windows/win32/winrm/installation-and-configuration-for-windows-remote-management)

## MediaArea requirements not handled by this Ansible project
- Ubuntu WSL2 subsystem with the following packages:
  - pkgconf
  - make
  - nasm

- Embarcadero C++ Studio 11.3 with the following GetIt packages:
  - VCL Windows Style - Windows11 Dark
  - EdgeView2 SDK
