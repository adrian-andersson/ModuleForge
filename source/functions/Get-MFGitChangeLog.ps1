function Get-MFGitChangeLog
{
<#
    .SYNOPSIS
        Generates a markdown changelog from Git commit messages between the latest and previous tags.

    .DESCRIPTION
        This function retrieves Git commit messages between the latest and previous tags, categorizes them based on predefined types, and formats them into a markdown changelog. It ensures the Git environment is correctly set up and handles errors if Git is not recognized or tags are not found.

    .EXAMPLE
        get-mfGitChangeLog
    
        DESCRIPTION
        Call the `get-mfGitChangeLog` function with default change Log Types. The function will generate a markdown changelog that can be sent to release or artifact notes.
        
        #### OUTPUT
        # Change Log
        Version: v1.0.0 --> v1.1.0
        ## New Features
        - Added new authentication module
        ## Bug Fixes
        - Fixed issue with user login

    .EXAMPLE
        get-mfGitChangeLog -changeLogTypes @{
        'feat' = 'New Features'
        'fix' = 'Bug Fixes'
        'chore' = 'Chore and Pipeline work'
        'test' = 'Test Changes'
        }
        
        DESCRIPTION
        This example demonstrates how to call the `get-mfGitChangeLog` function with a custom set of changelog types, in case you want to control your own

        #### OUTPUT
        # Change Log
        Version: v1.0.0 --> v1.1.0
        ## New Features
        - Added new authentication module
        ## Bug Fixes
        - Fixed issue with user login
        ## Chore and Pipeline work
        - Updated GH Pipeline AutoBuildv3
        ## Test Changes
        - Added test to user login function

    .EXAMPLE
        get-mfGitChangeLog -All

        DESCRIPTION
        Generates a full markdown changelog with all versions.

        #### OUTPUT
        # Change Log
        ## Version: v1.0.0 --> v1.1.0
        ### New Features
        - Added new authentication module
        ### Bug Fixes
        - Fixed issue with user login
        ### Chore and Pipeline work
        - Updated GH Pipeline AutoBuildv3
        ### Test Changes
        - Added test to user login function
        ## Version: v1.0.0-prev001 --> v1.1.0
        ### New Features
        - Added function

    .EXAMPLE
        get-mfGitChangeLog -fromLastTag

        DESCRIPTION
        Generates markdown changelog from commit messages from the last tag until now (Head)

        #### OUTPUT
        # Change Log

        ### New Features
        - Added new authentication module
        ### Bug Fixes
        - Fixed issue with user login
        ### Chore and Pipeline work
        - Updated GH Pipeline AutoBuildv3
        ### Test Changes
        - Added test to user login function

    .INPUTS
        [hashtable] - Accepts changeLogTypes hashtable via parameter or pipeline

    .OUTPUTS
        [STRING] - Returns a Markdown Compatible string output that can be redirected to a file

    .NOTES
        Author: Adrian Andersson
    #>

    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([string])]
    PARAM(
        #Change Logs Types and corresponding Heading. Hashtable/Key Value Pair expected. Key = git type; Value = Heading
        [Parameter(ValueFromPipeline, ParameterSetName = 'Default')]
        [Parameter(ValueFromPipeline, ParameterSetName = 'All')]
        [Parameter(ValueFromPipeline, ParameterSetName = 'FromLastTag')]
        [hashtable]$ChangeLogTypes = @{
            'feat' = 'New Features'
            'fix' = 'Bug Fixes'
            'docs' = 'Documentation Changes'
            'refactor' = 'Code Rewrite/Refactor'
            'perf' = 'Performance Improvements'
            #'chore' = 'Chore and Pipeline work'
            #'test' = 'Testing'
        },
        #Switch to get a full changelog for ALL tags
        [Parameter(ParameterSetName = 'All', Mandatory)]
        [switch]$All,
        #Switch to get the changelog from the last tag until this point.
        [Parameter(ParameterSetName = 'FromLastTag', Mandatory)]
        [switch]$FromLastTag
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"
        $markDown = [System.Collections.Generic.List[string]]::new()
        $markDown.add("# Change Log`n")
    }
    
    process{
        write-verbose 'Check git commandline and directory is going to work the way we expect it to. Throw if it does not'
        try{
            $gitVer = git --version
            $gitFolder = git rev-parse --is-inside-work-tree
            $gitFolder = $gitFolder.trim()
            
        }catch{
            throw 'Error getting Git Version or working directory.'
        }

        if(!$gitVer)
        {
            throw 'Git Version undetermined'
        }
        if(!$gitFolder -or $gitFolder -notlike '*true*')
        {
            throw 'Git not recognised as inside work tree'
        }

        write-verbose 'Get the Git Tags. Use the count of tags to determine if we are bundling for a release'
        #If you run this after tests and build, then creating a new release w/ tag, then you will KNOW that the tag is the new version
        $tags = @(git tag --sort=-creatordate)
        $tagCount  = $tags.count
        write-verbose "Got $tagCount total tags; ($($tags -join ','))"
        if($tagCount -gt 1 -and -not $FromLastTag)
        {
            if($All)
            {
                write-verbose 'AllFlag set. Getting complete Change Log'
                $tagRef = 1 #We need a marker to know what the next tag is. Since we start at 0, the ref should start at 1
                
                $tags.foreach{
                    write-verbose "Getting contents for $_. Reference: $tagRef"
                    $t1 = $_
                    $markDown.add("## Version: $t1`n")
                    if($tagRef -eq $tagCount){
                        write-verbose 'Last Entry?'
                        write-verbose "git log `"$($t1)`" --pretty=format:`"%s`""
                        $commitMessages = git log "$($t1)" --pretty=format:"%s"
                    }else{
                        $t2 = $tags[$tagRef]
                        write-verbose "git log `"$($t2)..$($t1)`" --pretty=format:`"%s`""
                        $commitMessages = git log "$($t2)..$($t1)" --pretty=format:"%s"
                    }
                        
                    $commitObjects = $commitMessages.forEach{if($_ -like '*:*'){$s = $_.split(":");[PSCustomObject]@{Type = $s[0].trim();Message = $s[1].trim()}}}
                    $grouped = $commitObjects.where{$_.type -in $ChangeLogTypes.getEnumerator().name} | group-object -property 'type'
                    $grouped.forEach{
                        $markDown.Add("`n### $($ChangeLogTypes.$($_.name))`n")
                        $_.group.Message.ForEach{
                            $markDown.Add("- $_")
                        }
                        $markDown.Add("`n")
                    }
                    
                    $tagRef++
                }
            }else{
                #Only get between the latest and previous release based on tag
                write-verbose "Found $tagCount total tags. Sorting to get latest and previous"
                $commitMessages = git log "$($tags[1])..$($tags[0])" --pretty=format:"%s"
                $markDown.add("## Version: $($tags[1]) --> $($tags[0])`n")
            }
        }elseIf($FromLastTag -and $tagCount -gt 0){
                write-verbose "fromLastTag set. Getting changelog from the last tagging event until now"
                write-verbose "Found $tagCount total tags. Sorting to get latest and previous"
                $commitMessages = git log "$($tags[0])..HEAD" --pretty=format:"%s"
        }else{
            #Get all and assume this is the first tag
            write-verbose 'Either Single Tag found or no tags found. Get all Commit messages to this point'
            $commitMessages = git log --pretty=format:"%s"
        }

        if(!$All -and $commitMessages)
        {
            write-verbose 'Getting Commit Objects, grouping and parsing based on changeLogTypes variable'
            $commitObjects = $commitMessages.forEach{if($_ -like '*:*'){$s = $_.split(":");[PSCustomObject]@{Type = $s[0].trim();Message = $s[1].trim()}}}
            $grouped = $commitObjects.where{$_.type -in $ChangeLogTypes.getEnumerator().name} | group-object -property 'type'
            $grouped.forEach{
                $markDown.Add("`n## $($ChangeLogTypes.$($_.name))`n")
                $_.group.Message.ForEach{
                    $markDown.Add("- $_")
                }
            }    
        }
        
        write-verbose 'Converting to Markdown String'
        $markDownText = $markDown -join "`n" 
        write-verbose "markDownLines = $($markDown.count)"
        #Check we have enough relevant commit messages to return a changelog
        #Basically, markDown should be gt 1, as the first line will be # changeLog.
        if($markDownText -and $markDown.count -gt 1){
            return $markDownText
        }else{
            return "# No relevant commit messages to convert to changelog"
        }
    }
}