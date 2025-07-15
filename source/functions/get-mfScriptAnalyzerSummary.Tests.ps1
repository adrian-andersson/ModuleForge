BeforeAll{

    #Reference Current Path
    $currentPath = $(get-location).path
    

    
    #Create a temp folder so we don't clobber anything
    $testPath = join-path -path $currentPath -childPath 'psInvokeTest'
    $sourcePath = join-path $testPath -ChildPath 'Source'
    $functionsPath = join-path $sourcePath -ChildPath functions
    $functionsFile = join-path $functionsPath -ChildPath 'test.ps1'

    if(!(test-path $testPath)){
        new-item -ItemType Directory -Path $testPath
    }
    if(!(test-path $sourcePath)){
        new-item -ItemType Directory -Path $sourcePath
    }
    if(!(test-path $functionsPath)){
        new-item -ItemType Directory -Path $functionsPath
    }

    $testFunction = @(
        'function get-text {'
        '    param ('
        '        [string]$returnString = "Hello"'
        '    )'
        '    process {'
        '        write-host "something"'
        '        return $returnString'
        '    }'
        '}'
    ) -join "`n"
    $testFunction | Out-File $functionsFile

    set-location $testPath
    
    #Load This File
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')

    #Need to ensure PSScriptAnalyzer is available 
    if(! (get-module 'PSScriptAnalyzer' -ListAvailable))
    { 
        install-module -Repository 'PSGallery' -Name PSScriptAnalyzer -Force -SkipPublisherCheck
    }


}

describe 'get-mfScriptAnalyzerSummary' {
    BeforeAll{
        $output = get-mfScriptAnalyzerSummary $sourcePath
    }

    It 'Should have returned 2 objects' {
        $output.count |should -be 2
    }

    It 'Should have returned an error for using WriteHost' {
        $output[0].RuleName | should -be 'PSAvoidUsingWriteHost'
    }

    It 'Should have returned a summary with 1 warning' {
        $output[1].Warnings | should -be 1
    }
}

afterAll {

    Set-Location $currentPath
    Remove-Item $testPath -Force -Recurse -ErrorAction Ignore
    start-sleep -Seconds 2 #Give it 2 seconds to remove the folder
}