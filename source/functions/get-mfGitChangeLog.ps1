function get-mfGitChangeLog
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

        .NOTES
        Author: Adrian Andersson
        Date: 2025-05-14
    #>


    [CmdletBinding()]
    PARAM(
        #Change Logs Types and corresponding Heading. Hashtable/Key Value Pair expected. Key = git type; Value = Heading
        [Parameter()]
        [hashtable]$changeLogTypes = @{
            'feat' = 'New Features'
            'fix' = 'Bug Fixes'
            'docs' = 'Documentation Changes'
            'refactor' = 'Code Rewrite/Refactor'
            'perf' = 'Performance Improvements'
            #'chore' = 'Chore and Pipeline work'
            #'test' = 'Testing'
        }
    )
    begin{
        #Return the script name when running verbose, makes it tidier
        write-verbose "===========Executing $($MyInvocation.InvocationName)==========="
        #Return the sent variables when running debug
        Write-Debug "BoundParams: $($MyInvocation.BoundParameters|Out-String)"

        
        
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
        $tags = git tag --sort=-creatordate
        $tagCount  = $tags.count
        if($tagCount  -gt 1)
        {
            #Only get between the latest and previous release based on tag
            write-verbose "Found $tagCount total tags. Sorting to get latest and previous"
            $commitMessages = git log "$($tags[1])..$($tags[0])" --pretty=format:"%s"
        }elseIf($tagCount  -eq 1){
            #Get all and assume this is the first tag
            write-verbose 'Single Tag found. Get all Commit messages to this point'
            $commitMessages = git log --pretty=format:"%s"
        }else{
            #Assume there isn't any tags and we aren't bundling this up for a release
            Write-Warning 'No tags found. May not be a release. This function gets the change log between the previous tag and latest tag. If you are not using Tags this function will not work'
        }


        $commitObjects = $commitMessages.forEach{if($_ -like '*:*'){$s = $_.split(":");[PSCustomObject]@{Type = $s[0].trim();Message = $s[1].trim()}}}
        if($commitObjects.count -ge 1){

            
            $grouped = $commitObjects.where{$_.type -in $changeLogTypes.getEnumerator().name} | group-object -property 'type'
            if($grouped.count -ge 1)
            {
                $markDown = [System.Collections.Generic.List[string]]::new()
                $markDown.add("# Change Log`n")
                if($tagCount -gt 1)
                {
                    $markDown.add("Version: $($tags[1]) --> $($tags[0])`n")
                }else{
                    $markDown.add("Version: $tags`n")
                }
                $grouped.forEach{
                    $markDown.Add("`n## $($changeLogTypes.$($_.name))`n")
                    $_.group.Message.ForEach{
                        $markDown.Add("- $_")
                    }
                }
                write-verbose 'Building Markdown Message'
                $markDownText = $markDown -join "`n" 
                if($markDownText){
                    return $markDownText
                }
            }else{
                Write-warning 'No Relevant Commit Messages'
            }
        
        }else{
            write-warning 'No Relevant Commit Messages Found'
        }
        
    }
    
}