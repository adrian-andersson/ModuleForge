function Get-MFBuildSummary
{

    <#
        .SYNOPSIS
            Summarise a build: its version, exports, size and file hashes, with a markdown version for CI.

        .DESCRIPTION
            Reads the compiled module in the build folder and reports what was built. The SHA256 hashes let anyone
            check that a published module matches this build, which matters most on platforms such as Azure DevOps,
            where a build has no release page to publish them on.

            The Markdown property suits a GitHub job summary ($env:GITHUB_STEP_SUMMARY) or an Azure DevOps build
            summary (##vso[task.uploadsummary]).

        ------------
        .EXAMPLE
            Get-MFBuildSummary

            #### DESCRIPTION
            Summarise the module in the build folder.

        .EXAMPLE
            (Get-MFBuildSummary -NugetPackagePath $nuRef).Markdown | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Append

            #### DESCRIPTION
            Add the summary, including the package's size and hash, to a GitHub Actions job summary.

        .OUTPUTS
            [PSCustomObject] - ModuleName, Version, PowerShellVersion, FunctionCount, AliasCount, BuildSizeKB, Files and Markdown

        .NOTES
            Author: Adrian Andersson

    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    PARAM(
        #Root path of the module. Uses the current working directory by default
        [Parameter(ValueFromPipelineByPropertyName)]
        [alias('Path')]
        [string]$ModulePath = $(get-location).path,
        #Name of the ModuleForge config file. Defaults to 'moduleForgeConfig.xml'
        [Parameter(DontShow)]
        [string]$ConfigFile = 'moduleForgeConfig.xml',
        #Path to the nupkg made from this build, to include its size and hash
        [Parameter()]
        [string]$NugetPackagePath
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
    }

    process{
        $configPath = join-path -path $ModulePath -ChildPath $ConfigFile
        if(!(test-path $configPath))
        {
            throw "Unable to find config file at: $configPath"
        }
        $moduleName = (import-clixml $configPath -erroraction stop).moduleName

        $moduleFolder = join-path -path (join-path -path $ModulePath -ChildPath 'build') -ChildPath $moduleName
        $manifestPath = join-path -path $moduleFolder -ChildPath "$moduleName.psd1"
        if(!(test-path $manifestPath))
        {
            throw "Unable to find a built manifest at: $manifestPath. Run Build-MFProject first"
        }
        $manifest = Import-PowerShellDataFile -Path $manifestPath

        $version = if($manifest.PrivateData.PSData.Prerelease){"$($manifest.ModuleVersion)-$($manifest.PrivateData.PSData.Prerelease)"}else{"$($manifest.ModuleVersion)"}
        $builtFiles = @(Get-ChildItem -Path $moduleFolder -File -Recurse)

        #The manifest and module files, plus any external scripts the build wrote beside them
        $hashFiles = @($builtFiles | Where-Object { $_.DirectoryName -eq $moduleFolder -and $_.Extension -in '.psd1','.psm1','.ps1' } | Sort-Object -Property @{Expression={@('.psd1','.psm1','.ps1').IndexOf($_.Extension)}},'Name')
        if($NugetPackagePath)
        {
            $hashFiles += Get-Item -Path $NugetPackagePath -ErrorAction Stop
        }
        $files = foreach($file in $hashFiles)
        {
            [PSCustomObject]@{
                Name = $file.Name
                SizeKB = [math]::Round($file.Length / 1kb, 1)
                SHA256 = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash.ToLower()
            }
        }

        $buildSizeKB = [math]::Round((($builtFiles | Measure-Object -Property Length -Sum).Sum) / 1kb, 1)
        $functionCount = @($manifest.FunctionsToExport | Where-Object { $_ -and $_ -ne '*' }).Count
        $aliasCount = @($manifest.AliasesToExport | Where-Object { $_ -and $_ -ne '*' }).Count

        $markdown = @(
            '### 📦 Build Summary'
            ''
            '|||'
            '|-|-|'
            "|Module|$moduleName|"
            "|Version|$version|"
            "|Minimum PowerShell|$($manifest.PowerShellVersion)|"
            "|Exported functions|$functionCount|"
            "|Exported aliases|$aliasCount|"
            "|Build size|$buildSizeKB KB across $($builtFiles.Count) files|"
            ''
            '#### 🔐 SHA256'
            ''
            '|File|Size|SHA256|'
            '|-|-|-|'
            $files.ForEach{ "|$($_.Name)|$($_.SizeKB) KB|``$($_.SHA256)``|" }
            ''
        ) -join "`n"

        [PSCustomObject]@{
            ModuleName = $moduleName
            Version = $version
            PowerShellVersion = $manifest.PowerShellVersion
            FunctionCount = $functionCount
            AliasCount = $aliasCount
            BuildSizeKB = $buildSizeKB
            Files = @($files)
            Markdown = $markdown
        }
    }

}
