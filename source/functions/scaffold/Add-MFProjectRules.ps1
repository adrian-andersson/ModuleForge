function Add-MFProjectRules
{

    <#
        .SYNOPSIS
            Adds example Project Rules to a ModuleForge project, and enables the Project Rules workflow or pipeline.

        .DESCRIPTION
            Project Rules run a project's own PSScriptAnalyzer rules, from a PSScriptAnalyzer folder in the project root,
            as an advisory pass with its own pull request comment. This copies ready-made rule sets into that folder:

              - CLM           PSScriptAnalyzer settings that check for Constrained Language Mode compatibility,
                              with the PSUseConstrainedLanguageMode rule. Needs PSScriptAnalyzer 1.25.0 or newer
              - HelpExamples  A custom rule that warns when a public function has no .EXAMPLE in its help,
                              as the docs are generated from it

            It then enables the Project Rules workflow in .github and the pipeline in .azuredevops, whichever exist,
            by renaming projectRules.yml.example to projectRules.yml, or adding it if it is missing. Azure DevOps
            still needs a pipeline creating for the file. It also adds any missing project scripts, as the workflow
            calls scripts/Invoke-MFProjectRules.ps1, which you can also run locally.

            Existing files are skipped unless -Force is used.

        .EXAMPLE
            Add-MFProjectRules

            #### DESCRIPTION
            Adds both rule sets to the PSScriptAnalyzer folder, and enables Project Rules in the CI folders that exist.

            #### OUTPUT
            PSScriptAnalyzer/clm.psd1, PSScriptAnalyzer/rules/HelpExamples/HelpExamples.psm1, and an enabled
            projectRules.yml in .github/workflows or .azuredevops/pipelines.

        .EXAMPLE
            Add-MFProjectRules -RuleSet CLM

            #### DESCRIPTION
            Adds only the Constrained Language Mode check.

        .EXAMPLE
            .\scripts\Invoke-MFProjectRules.ps1 -InstallPSScriptAnalyzer

            #### DESCRIPTION
            After adding rules, run them locally the same way the workflow does.

        .NOTES
            Author: Adrian Andersson

    #>

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessage("PSUseSingularNouns", "", Justification = "Plural 'Rules' matches the Project Rules feature it sets up.")]
    PARAM(
        #Which rule sets to add. Adds all of them by default
        [Parameter()]
        [ValidateSet('CLM','HelpExamples')]
        [string[]]$RuleSet = @('CLM','HelpExamples'),
        #Root path of the module. Uses the current working directory by default
        [Parameter()]
        [alias('Path')]
        [string]$ModulePath = $(Get-Location).path,
        #Module Config reference
        [Parameter(DontShow)]
        [string]$ConfigFile = 'moduleForgeConfig.xml',
        #Overwrite rule files and enabled workflows that already exist
        [switch]$Force
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
        if($mockPsScriptRoot)
        {
            #Assume we are in pester test, and use the $mockPsScriptRoot param
            write-warning 'Assuming PSScriptRoot from $mockPsScriptRoot. This should only be done for testing'
            $resourceFolder = Join-Path $mockPsScriptRoot 'resource'
        }else{
            $resourceFolder = Join-Path $PSScriptRoot 'resource'
        }
        write-verbose "ResourceFolder: $resourceFolder"

        $resourceFolderRules = Join-Path $resourceFolder 'projectRules'
        if(!(Test-Path $resourceFolderRules))
        {
            throw 'Err: Unable to find the projectRules folder in the ModuleForge module resources'
        }

        if(!(Test-Path (Join-Path $ModulePath $ConfigFile)))
        {
            throw 'Err: No Moduleforge Config File found. Please check your module path'
        }

        #The files each rule set adds, relative to the PSScriptAnalyzer folder
        $ruleSetFiles = @{
            CLM = @('clm.psd1')
            HelpExamples = @('rules/HelpExamples/HelpExamples.psm1')
        }

        #Where each CI platform keeps the Project Rules template, in the project and in ModuleForge's resources
        $platforms = @(
            @{ Name = 'GitHub'; ProjectFolder = '.github'; SubFolder = 'workflows'; ResourceFolder = 'github' }
            @{ Name = 'Azure DevOps'; ProjectFolder = '.azuredevops'; SubFolder = 'pipelines'; ResourceFolder = 'azureDevOps' }
        )
    }

    process{
        $rulesFolder = Join-Path $ModulePath 'PSScriptAnalyzer'
        foreach($set in @($RuleSet | Select-Object -Unique))
        {
            foreach($relativePath in $ruleSetFiles[$set])
            {
                $source = Join-Path $resourceFolderRules $relativePath
                $destination = Join-Path $rulesFolder $relativePath
                if((Test-Path $destination) -and !$Force)
                {
                    write-warning "Skipping $destination as it exists"
                    continue
                }
                $destinationFolder = Split-Path $destination -Parent
                if(!(Test-Path $destinationFolder))
                {
                    $null = New-Item -ItemType Directory -Path $destinationFolder -Force
                }
                write-verbose "Adding the $set rule set: $destination"
                Copy-Item -Path $source -Destination $destination -Force
            }
        }

        $enabledAny = $false
        foreach($platform in $platforms)
        {
            $projectFolder = Join-Path $ModulePath $platform.ProjectFolder
            if(!(Test-Path $projectFolder))
            {
                write-verbose "No $($platform.ProjectFolder) folder, so not enabling Project Rules for $($platform.Name)"
                continue
            }
            $enabledAny = $true
            $templateFolder = Join-Path $projectFolder $platform.SubFolder
            if(!(Test-Path $templateFolder))
            {
                $null = New-Item -ItemType Directory -Path $templateFolder -Force
            }
            $active = Join-Path $templateFolder 'projectRules.yml'
            $example = Join-Path $templateFolder 'projectRules.yml.example'
            $resourceTemplate = Join-Path $resourceFolder $platform.ResourceFolder -AdditionalChildPath $platform.SubFolder,'projectRules.yml.example'
            if(!(Test-Path $active))
            {
                if(Test-Path $example)
                {
                    #Rename rather than copy, to keep any changes made to the example
                    write-verbose "Enabling $($platform.Name) Project Rules: renaming $example"
                    Rename-Item -Path $example -NewName 'projectRules.yml'
                }else{
                    write-verbose "Enabling $($platform.Name) Project Rules: adding $active"
                    Copy-Item -Path $resourceTemplate -Destination $active
                }
            }elseif($Force){
                write-warning "Overwrite $active"
                Copy-Item -Path $resourceTemplate -Destination $active -Force
            }else{
                write-verbose "$($platform.Name) Project Rules is already enabled"
            }
            if($platform.Name -eq 'Azure DevOps')
            {
                write-warning "Azure DevOps does not create pipelines automatically. Create a pipeline for $active and add it to build validation on your main branch"
            }
        }
        if(!$enabledAny)
        {
            write-warning 'No .github or .azuredevops folder, so no workflow was enabled. Run the rules locally with .\scripts\Invoke-MFProjectRules.ps1, or add a CI scaffold and run this again'
        }

        #The workflows call scripts/Invoke-MFProjectRules.ps1, and older projects may not have it. Skips existing files
        Add-MFProjectScripts -ModulePath $ModulePath -WarningAction SilentlyContinue
    }

}
