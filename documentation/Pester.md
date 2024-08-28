# Pester Testing

You should be trying to achieve the default pester code-coverage for all your functions, it will absolutely save you time, especially if your modules are being built with an orchestration tool like Github Actions.


The process might look like this:

1. Checkout the repository
1. Invoke Pester, and if successful
1. Build the module with a new PreRelease version, and if successful
1. Publish the module, either to PSGallery or a private repository (Like GH Packages)
1. Use the pre-release module to confirm it works well
1. Publish a non-prerelease version. 

## Some problems with testing modules

You can in theory pester-test your module psm1 file. That would ensure all your related functions, classes and enums are all together, but then your effectively compiling the module first and testing later. Also, doing it this way also causes code-coverage problems with scoping. If you use pesters inModuleScope, you get complicated code coverage problems. And it's not very flexible. How do you know if the problem was in the dependent function or the main function?

A better way, and the way Pester was meant to work, would be to run Pester on the source/functions folder, but that also presents a scoping and dependency problem. For example, if you have function1 in functions/function1.ps1, and it relies on privatefunction2 in private/function2.ps1, you need to either Mock privatefunction2, or you need to reference it in your BeforeAll. That seems simple enough, but suppose you went hard on dependencies, you have lots of smaller functions and one big main function that calls all those little functions, dot sourcing them all could be complicated, and quickly get unmanigible for each test your writing.

I've solved this by adding a `get-mfDependencyTree` function to moduleForge, you can use it like this

```PowerShell
$folderItemDetails = get-mfFolderItemDetails -path $sourcePath
get-mfDependencyTree -referenceData $($folderItemDetails|Select-Object relativePath,Dependencies)

```

That will output this:

```PowerShell
.\source\functions\build-mfProject.ps1
     >--DEPENDS-ON--> .\source\functions\get-mfDependencyTree.ps1
     >--DEPENDS-ON--> .\source\functions\get-mfFolderItemDetails.ps1
         >--DEPENDS-ON--> .\source\functions\get-mfFolderItems.ps1
     >--DEPENDS-ON--> .\source\functions\get-mfFolderItems.ps1
.\source\functions\get-mfFolderItemDetails.ps1
     >--DEPENDS-ON--> .\source\functions\get-mfFolderItems.ps1
.\source\functions\new-mfProject.ps1
     >--DEPENDS-ON--> .\source\private\add-mfFilesAndFolders.ps1
```

And then in the BeforeAll block of the Pester Tests, I just include the relevant dependencies.
I've simplified this for my pester tests with this code:

```PowerShell
BeforeAll{

    #Reference Current Path
    $currentPath = $(get-location).path
    $sourcePath = join-path -path $currentPath -childPath 'source'

    $dependencies = [ordered]@{
        enums = @('enum1.ps1')
        validationClasses = @('validator1.ps1')
        classes = @('class1.ps1')
        functions = @('function1.ps1')
        private = @('function2.ps1')
    }

    $dependencies.GetEnumerator().ForEach{
        $DirectoryRef = join-path -path $sourcePath -childPath $_.Key
        $_.Value.ForEach{
            $ItemPath = join-path -path $DirectoryRef -childpath $_
            $ItemRef = get-item $ItemPath -ErrorAction SilentlyContinue
            if($ItemRef){
                write-verbose "Dependency identified at: $($ItemRef.fullname)"
                . $ItemRef.Fullname
            }else{
                write-warning "Dependency not found at: $ItemPath"
            }
        }
    }
    
    #Load This File
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')
}

```

This allows me to quickly add any dependencies I may have and to get on with the testing.