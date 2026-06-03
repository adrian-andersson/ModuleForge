function Write-MFModuleDocs
{

    <#
        .SYNOPSIS
            Generates and updates function documentation using PlatyPS, and creates an index for module functions.

        .DESCRIPTION
            Automates documentation generation based on module functions, leveraging PlatyPS to create and
            update Markdown help files. Injects Just The Docs front matter into every generated page so the
            Jekyll sidebar renders a proper navigation hierarchy without manual editing.

            The -StampAllDocs switch extends that treatment to the entire docs folder: it scans every
            subdirectory, creates parent index pages with child link lists, and non-destructively injects
            front matter into any page that does not already carry a 'layout:' field. Pages with existing
            Just The Docs front matter are never modified.

        .EXAMPLE
            Write-MFModuleDocs -ModuleName 'MyCustomModule' -IncludeChangeLog

            #### DESCRIPTION
            Builds documentation for MyCustomModule and includes a full Git-based changelog alongside
            function help files.

        .EXAMPLE
            Write-MFModuleDocs -ModuleName 'MyCustomModule' -StampAllDocs -IncludeChangeLog

            #### DESCRIPTION
            Generates function docs, stamps all existing docs pages with Just The Docs front matter,
            and produces a changelog. Ideal for a CI pipeline docs update step.

        .EXAMPLE
            Write-MFModuleDocs -ModuleName 'MyCustomModule' -SkipIndex

            #### DESCRIPTION
            Generates function documentation without updating index.md.

        .INPUTS
            [string] - ModulePath is accepted as pipeline input or via direct assignment.

        .NOTES
            Author: Adrian Andersson

    #>

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification='Plural Docs reflects a short form of documentation')]
    PARAM(
        #The root path where documentation should be stored. Defaults to the current directory.
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [alias('Path')]
        [string]$ModulePath = $(get-item .).fullname,
        #The name of the PowerShell module for which documentation should be generated.
        [Parameter(Mandatory)]
        [alias('module')]
        [ValidateScript({ Get-Module -Name $_ -ErrorAction SilentlyContinue })]
        [string]$ModuleName,
        #Specify the docs folder. All files and index.md will be created here and in subfolders. Defaults to 'docs'.
        [Parameter()]
        [alias('docsPath')]
        [string]$DocsFolder = 'docs',
        #Subfolder within DocsFolder where function documentation is stored. Defaults to 'functions'.
        [Parameter()]
        [alias('functionsPath')]
        [string]$FunctionsFolder = 'functions',
        #If specified, retrieves and includes a Markdown changelog based on Git commit history.
        [Parameter()]
        [switch]$IncludeChangeLog,
        #If specified, skips creating or updating the index.md homepage.
        [Parameter()]
        [switch]$SkipIndex,
        #If specified, scans all subdirectories of the docs folder and non-destructively injects
        #Just The Docs front matter into pages that do not already have a 'layout:' field.
        #Creates parent index pages with child link lists where none exist.
        [Parameter()]
        [switch]$StampAllDocs
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        $platyPs = (get-module -Name PlatyPS -ListAvailable|Sort-Object -Property version -Descending|select-object -first 1)
        if($platyPs)
        {
            write-verbose "Build Function Documentation with PlatyPS Version $($platyPs.version)"
        }else{
            throw "This function relies on module PlatyPS. Please install it from the PSGallery"
        }

        $module = (get-module -Name $ModuleName|Sort-Object -Property version -Descending|select-object -first 1)
        if($module)
        {
            write-verbose "Build Function Documentation for Module $ModuleName - version: $($module.version)"
        }else{
            throw "Module is not pre-loaded. Please import the module first"
        }
    }

    process{
        write-verbose "In path $ModulePath"
        $DocsFullPath = join-path -Path $ModulePath -ChildPath $DocsFolder
        write-verbose "DocsFullPath: $($DocsFullPath)"
        if(!(test-path $DocsFullPath))
        {
            write-verbose 'Need to make docs folder as it does not exist'
            New-Item -ItemType Directory -Path $DocsFullPath
        }

        # Phase 0 — snapshot all existing front matter before any writes.
        # Stores a flat key→value dictionary per page so that hand-crafted fields
        # (nav_order, custom titles, etc.) survive regeneration. Keys are
        # forward-slash relative paths from DocsFullPath (e.g. 'functions/index.md').
        $frontMatterCache = @{}
        $existingMdFiles  = Get-ChildItem $DocsFullPath -Filter '*.md' -Recurse -ErrorAction SilentlyContinue
        foreach($existingFile in $existingMdFiles)
        {
            $existingContent = Get-Content $existingFile.FullName -Raw -ErrorAction SilentlyContinue
            if($existingContent -and $existingContent -match '(?s)^---\r?\n(.*?)\r?\n---')
            {
                $fmDict = [ordered]@{}
                foreach($fmLine in ($Matches[1] -split '\r?\n'))
                {
                    if($fmLine -match '^([\w][\w_ -]*):\s*(.+)$')
                    {
                        $fmDict[$Matches[1].Trim()] = $Matches[2].Trim()
                    }
                }
                $relPath = $existingFile.FullName.Substring($DocsFullPath.Length).TrimStart([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar).Replace('\','/')
                $frontMatterCache[$relPath] = $fmDict
            }
        }
        write-verbose "Front matter snapshot: $($frontMatterCache.Count) pages cached"

        $functionsFullPath = join-path -Path $DocsFullPath -ChildPath $FunctionsFolder
        if(!(test-path $functionsFullPath))
        {
            write-verbose 'Need to make functions folder as it does not exist'
            New-Item -ItemType Directory -Path $functionsFullPath
        }else{
            write-verbose 'Recreating Functions Folder'
            try{
                remove-item $functionsFullPath -ErrorAction Stop -Force -Recurse
            }catch{
                throw 'Error cleaning up existing functions folder'
            }
            New-Item -ItemType Directory -Path $functionsFullPath
        }

        # Generate raw function docs via PlatyPS
        write-verbose 'Create markdown help from module help'
        New-MarkdownHelp -Module $module.Name -Force -OutputFolder $functionsFullPath

        # Post-process every generated function page:
        #   - merge JTD front matter with the existing PlatyPS front matter
        #   - strip the ProgressAction parameter section (PS7 noise)
        $functionsNavTitle = ConvertTo-MFNavTitle -FolderName $FunctionsFolder
        write-verbose "Injecting JTD front matter into function pages (parent: '$functionsNavTitle')"

        foreach($funcFile in (Get-ChildItem $functionsFullPath -Filter '*.md' | Where-Object {$_.Name -ne 'index.md'}))
        {
            $rawContent = Get-Content $funcFile.FullName -Raw

            # Parse and normalise the existing PlatyPS front matter
            $existingFm  = ''
            $bodyContent = $rawContent
            if($rawContent -match '(?s)^---\r?\n(.*?)\r?\n---\r?\n')
            {
                $existingFm  = $Matches[1] -replace '\r\n', "`n"
                $bodyContent = $rawContent.Substring($Matches[0].Length)
            }

            # Derive the page title from the H1 heading
            $pageTitle = $funcFile.BaseName
            if($bodyContent -match '(?m)^# (.+)')
            {
                $pageTitle = $Matches[1].Trim()
            }

            # Strip the ProgressAction parameter section line-by-line
            $bodyLines        = $bodyContent -split '(?:\r?\n)'
            $filteredLines    = [System.Collections.Generic.List[string]]::new()
            $inProgressAction = $false
            foreach($line in $bodyLines)
            {
                if($line -match '^### -ProgressAction')
                {
                    $inProgressAction = $true
                    continue
                }
                if($inProgressAction -and $line -match '^### ')
                {
                    $inProgressAction = $false
                }
                if(-not $inProgressAction){ $filteredLines.Add($line) }
            }
            $cleanBody = $filteredLines -join "`n"

            # Build merged front matter: JTD fields first, then original PlatyPS fields
            $jtdFields = "layout: default`ntitle: $pageTitle`nparent: $functionsNavTitle"
            $mergedFm  = if($existingFm){"$jtdFields`n$existingFm"}else{$jtdFields}

            "---`n$mergedFm`n---`n$cleanBody" | Out-File $funcFile.FullName -Force
        }

        # Create the functions/index.md parent page with a full child link list
        write-verbose "Creating $FunctionsFolder parent index page"
        $funcMdFiles    = Get-ChildItem $functionsFullPath -Filter '*.md' | Where-Object {$_.Name -ne 'index.md'}
        $funcChildLinks = Get-MFChildLinkList -MdFiles $funcMdFiles -SubDirs @()

        # Restore any hand-crafted front matter fields from the snapshot
        $funcIndexCacheKey = "$FunctionsFolder/index.md"
        $savedFuncFm = if($frontMatterCache.Contains($funcIndexCacheKey)){ $frontMatterCache[$funcIndexCacheKey] }else{ @{} }

        $funcIndexLines = [System.Collections.Generic.List[string]]::new()
        $funcIndexLines.Add('---')
        $funcIndexLines.Add('layout: default')
        $funcIndexLines.Add("title: $functionsNavTitle")
        $funcIndexLines.Add('has_children: true')
        $funcIndexLines.Add("permalink: /$FunctionsFolder/")
        if($savedFuncFm.Contains('nav_order')){ $funcIndexLines.Add("nav_order: $($savedFuncFm['nav_order'])") }
        $funcIndexLines.Add('---')
        $funcIndexLines.Add('')
        $funcIndexLines.Add("# $functionsNavTitle")
        $funcIndexLines.Add('')
        $funcIndexLines.Add("Reference documentation for all exported $ModuleName functions.")
        $funcIndexLines.Add('')
        foreach($link in $funcChildLinks){ $funcIndexLines.Add($link) }
        $funcIndexLines -join "`n" | Out-File (join-path $functionsFullPath 'index.md') -Force

        # Changelog — prepend JTD front matter, restoring nav_order from the snapshot if present
        if($IncludeChangeLog)
        {
            write-verbose 'Creating changelog file'
            $changeLog = get-mfGitChangeLog -all
            write-verbose "ChangeLog: `n$($changeLog)"
            if($changeLog)
            {
                $changeLogPath    = join-path $DocsFullPath -ChildPath 'changeLog.md'
                $savedClFm        = if($frontMatterCache.Contains('changeLog.md')){ $frontMatterCache['changeLog.md'] }else{ @{} }
                $changeLogNavOrder = if($savedClFm.Contains('nav_order')){ $savedClFm['nav_order'] }else{ 2 }
                $changeLogFm      = "---`nlayout: default`ntitle: Change Log`nnav_order: $changeLogNavOrder`n---`n`n"
                $changeLogBody    = if($changeLog -is [array]){ $changeLog -join "`n" }else{ $changeLog.ToString() }
                $changeLogFm + $changeLogBody | Out-File $changeLogPath -Force
            }else{
                write-warning 'changeLog notes were not captured as none existed, or something went wrong'
            }
        }

        # StampAllDocs  - walk every subdirectory except the functions folder and non-destructively
        # inject JTD front matter + create parent index pages wherever they are missing.
        if($StampAllDocs)
        {
            write-verbose 'StampAllDocs: scanning docs folder'
            $otherDirs = Get-ChildItem $DocsFullPath -Directory | Where-Object {$_.Name -ne $FunctionsFolder}

            foreach($sectionDir in $otherDirs)
            {
                # Skip directories that contain no markdown content at any depth
                $allMd = Get-ChildItem $sectionDir.FullName -Filter '*.md' -Recurse -ErrorAction SilentlyContinue
                if(-not $allMd -or $allMd.Count -eq 0)
                {
                    write-verbose "StampAllDocs: skipping '$($sectionDir.Name)'  - no markdown files"
                    continue
                }

                $sectionTitle  = ConvertTo-MFNavTitle -FolderName $sectionDir.Name
                write-verbose "StampAllDocs: section '$sectionTitle'"

                $directMdFiles = Get-ChildItem $sectionDir.FullName -Filter '*.md' | Where-Object {$_.Name -ne 'index.md'}
                $childSubDirs  = Get-ChildItem $sectionDir.FullName -Directory -ErrorAction SilentlyContinue |
                                    Where-Object {(Get-ChildItem $_.FullName -Filter '*.md' -ErrorAction SilentlyContinue).Count -gt 0}

                # Non-destructively stamp direct child pages
                foreach($mdFile in $directMdFiles)
                {
                    if(!(Test-MFHasJtdFrontMatter -FilePath $mdFile.FullName))
                    {
                        $h1    = Get-MFH1FromFile -FilePath $mdFile.FullName
                        $title = if($h1){ $h1 }else{ $mdFile.BaseName }
                        Add-MFJtdFrontMatter -FilePath $mdFile.FullName -Title $title -Parent $sectionTitle
                        write-verbose "StampAllDocs: stamped '$($mdFile.Name)'"
                    }else{
                        write-verbose "StampAllDocs: skipping '$($mdFile.Name)'  - already has JTD front matter"
                    }
                }

                # Create or update the section index.md (only when JTD front matter is absent)
                $sectionIndexPath = join-path $sectionDir.FullName 'index.md'
                if(!(test-path $sectionIndexPath) -or !(Test-MFHasJtdFrontMatter -FilePath $sectionIndexPath))
                {
                    $childLinks = Get-MFChildLinkList -MdFiles $directMdFiles -SubDirs $childSubDirs
                    Write-MFSectionIndex -FilePath $sectionIndexPath -Title $sectionTitle -ChildLinks $childLinks
                    write-verbose "StampAllDocs: wrote index for '$sectionTitle'"
                }else{
                    write-verbose "StampAllDocs: skipping index for '$sectionTitle'  - already has JTD front matter"
                }

                # Process depth-2 subdirectories (grandchildren in JTD terms)
                foreach($subDir in $childSubDirs)
                {
                    $subSectionTitle = ConvertTo-MFNavTitle -FolderName $subDir.Name
                    write-verbose "StampAllDocs: sub-section '$subSectionTitle' (parent: '$sectionTitle')"

                    $subMdFiles = Get-ChildItem $subDir.FullName -Filter '*.md' | Where-Object {$_.Name -ne 'index.md'}

                    # Warn about depth-3+ folders  - JTD renders at most 3 sidebar levels
                    $depth3Dirs = Get-ChildItem $subDir.FullName -Directory -ErrorAction SilentlyContinue
                    if($depth3Dirs)
                    {
                        write-warning "StampAllDocs: '$($subDir.Name)' has sub-folders beyond depth 2  - JTD renders at most 3 sidebar levels. These will not be auto-stamped."
                    }

                    # Non-destructively stamp grandchild pages
                    foreach($mdFile in $subMdFiles)
                    {
                        if(!(Test-MFHasJtdFrontMatter -FilePath $mdFile.FullName))
                        {
                            $h1    = Get-MFH1FromFile -FilePath $mdFile.FullName
                            $title = if($h1){ $h1 }else{ $mdFile.BaseName }
                            Add-MFJtdFrontMatter -FilePath $mdFile.FullName -Title $title -Parent $subSectionTitle -GrandParent $sectionTitle
                            write-verbose "StampAllDocs: stamped '$($mdFile.Name)' (parent: '$subSectionTitle', grand_parent: '$sectionTitle')"
                        }else{
                            write-verbose "StampAllDocs: skipping '$($mdFile.Name)'  - already has JTD front matter"
                        }
                    }

                    # Create or update the sub-section index.md
                    $subIndexPath = join-path $subDir.FullName 'index.md'
                    if(!(test-path $subIndexPath) -or !(Test-MFHasJtdFrontMatter -FilePath $subIndexPath))
                    {
                        $subChildLinks = Get-MFChildLinkList -MdFiles $subMdFiles -SubDirs @()
                        Write-MFSectionIndex -FilePath $subIndexPath -Title $subSectionTitle -Parent $sectionTitle -ChildLinks $subChildLinks
                        write-verbose "StampAllDocs: wrote index for '$subSectionTitle'"
                    }else{
                        write-verbose "StampAllDocs: skipping index for '$subSectionTitle'  - already has JTD front matter"
                    }
                }
            }
        }

        # Build the homepage (index.md)  - version-stamped intro with auto-discovered sections table
        if($SkipIndex)
        {
            write-verbose 'Skipping Index File'
        }else{
            write-verbose 'Creating homepage index'

            # Version string  - include prerelease label when present
            $moduleVersion = $module.Version.ToString()
            if($module.PrivateData.PSData.Prerelease)
            {
                $moduleVersion += "-$($module.PrivateData.PSData.Prerelease)"
            }
            $moduleDescription = $module.Description

            $indexLines = [System.Collections.Generic.List[string]]::new()
            $indexLines.Add('---')
            $indexLines.Add('layout: default')
            $indexLines.Add('title: Home')
            $indexLines.Add('nav_order: 1')
            $indexLines.Add('---')
            $indexLines.Add('')
            $indexLines.Add("# $ModuleName")
            $indexLines.Add('')
            $indexLines.Add("> Module version: $moduleVersion")
            $indexLines.Add('')

            if($moduleDescription)
            {
                $indexLines.Add($moduleDescription)
                $indexLines.Add('')
            }

            if($IncludeChangeLog)
            {
                $indexLines.Add('[Change Log](./changeLog.md)')
                $indexLines.Add('')
            }

            # Auto-discover sections from subdirectories of the docs folder
            $sectionDirs = Get-ChildItem $DocsFullPath -Directory | Sort-Object Name
            if($sectionDirs)
            {
                $indexLines.Add('## Sections')
                $indexLines.Add('')
                $indexLines.Add('| Section | |')
                $indexLines.Add('| --- | --- |')

                foreach($sDir in $sectionDirs)
                {
                    $sDirTitle     = ConvertTo-MFNavTitle -FolderName $sDir.Name
                    $sDirIndexPath = join-path $sDir.FullName 'index.md'
                    $sDirDesc      = ''

                    # Read the first plain-text paragraph after the H1 of the section index
                    if(test-path $sDirIndexPath)
                    {
                        $sDirLines = Get-Content $sDirIndexPath
                        $fmCount   = 0
                        $inFm      = $false
                        $pastH1    = $false
                        foreach($sLine in $sDirLines)
                        {
                            if($sLine -match '^---')
                            {
                                $fmCount++
                                $inFm = $fmCount -lt 2
                                continue
                            }
                            if($inFm){ continue }
                            if($sLine -match '^# '){ $pastH1 = $true; continue }
                            if($pastH1 -and $sLine.Trim() -ne '' -and $sLine -notmatch '^[#\-\|]')
                            {
                                $sDirDesc = $sLine.Trim()
                                break
                            }
                        }
                    }

                    $indexLines.Add("| [$sDirTitle](./$($sDir.Name)/) | $sDirDesc |")
                }
            }

            $indexPath = join-path $DocsFullPath 'index.md'
            if(Test-Path $indexPath)
            {
                # Homepage already exists — only update the version line to preserve the
                # hand-crafted sections table, root-level page links, and section names.
                $existingIndexContent = Get-Content $indexPath -Raw
                $updatedIndexContent  = $existingIndexContent -replace '(?m)^> Module version:.*$', "> Module version: $moduleVersion"
                $updatedIndexContent | Out-File $indexPath -Force -NoNewline
                write-verbose 'Homepage already exists — updated version line only'
            }else{
                # First run — generate the homepage from scratch
                $indexLines -join "`n" | Out-File $indexPath -Force
                write-verbose 'Generated new homepage'
            }
        }
    }

}
