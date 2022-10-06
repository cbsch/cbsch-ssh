# SSH/SCP argument completer

Adapted argument completer code from [posh-git](https://github.com/dahlbyk/posh-git) to work with ssh.

Will read ~/.ssh/config for `Host` entries and try to complete them with the ssh/scp commands.

https://www.powershellgallery.com/packages/cbsch-ssh

# Installation

```powershell
Install-Module -Name cbsch-ssh -Scope CurrentUser
```
