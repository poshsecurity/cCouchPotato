#cCouchPotato

A simple DSC module for maintaining a CouchPotato install

## Resources

* **CouchPotatoInstall** controls installation of CouchPotato

### SonarrInstall

Controls the installation (absent or present) of CouchPotato, also ensure that the software is automatically updated.

* **Ensure**: Ensure either Absent or Present (Installed and Updated)

## Versions

### 1.0

* Intial version
* Released to PowerShell Gallery

## Examples
### Ensure CouchPotato Installed

```powershell
configuration DownloadHostDSC
{
    Import-DscResource -ModuleName 'cCouchPotato'

    cCouchPotatoInstall CouchPotatoInstaller
    {
        Ensure    = 'Present'
    }
}
```

Ensures that CouchPotato is installed.

### Ensure CouchPotato not installed

```powershell
configuration DownloadHostDSC
{
    Import-DscResource -ModuleName 'cCouchPotato'

    cCouchPotato CouchPotatoInstaller
    {
        Ensure    = 'Absent'
    }
}
```

Ensures that CouchPotato is not installed.
