# A mermaid diagram

```Mermaid
flowchart TD
'.\source\functions\build-mfProject.ps1' --> '.\source\functions\get-mfFolderItems.ps1'
'.\source\functions\build-mfProject.ps1' --> '.\source\functions\get-mfScriptText.ps1'
'.\source\functions\get-mfFolderItemDetails.ps1' --> '.\source\functions\get-mfFolderItems.ps1'
'.\source\functions\get-mfFolderItemDetails.ps1' --> '.\source\functions\get-mfScriptDetails.ps1'
'.\source\functions\new-mfProject.ps1' --> '.\source\private\add-mfFilesAndFolders.ps1'
```
