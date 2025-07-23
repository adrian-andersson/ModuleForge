# Publishing your private modules to PSGallery

If you want to publish your modules to PSGallery, this workflow will get you started. It will push the latest released and packaged module to PSGallery.

## Step 1 - Add a repository secret for your PSGallery Token

> To create a PSGallery API key, visit: https://www.powershellgallery.com/account and log in. You'll find the "API Key" section under your account settings.

1. Open your repository and navigate to the `Settings` tab
2. Under  _Security_, find the _Secrets and variables_ section, and then select `Actions`
3. Add a _repository secret_
   - To match the Workflow below, name the secret `PSGALLERY`
   - Enter your PSGallery token

## Step 2 - Create a new Workflow

1. Under the .github\workflows folder, create a new file, call it `psgallery-release.yml`
2. Paste the below workflow code
3. Commit and merge to your main
4. Running this workflow will push the last tagged release to PSgallery

```yaml
name: PSGallery Latest Release

on:
  workflow_dispatch:

jobs:
  psgalleryDeploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: read

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3
        with:
          fetch-depth: 0 #Ensure we are getting all the tag history

      - name: Get latest release details
        id: get_release
        env:
          GH_TOKEN: ${{ github.token }}
        shell: pwsh
        run: |
          $verbosePreference = 'Continue'
          $release = gh release view --json tagName,name,body,createdAt,author,assets,isPrerelease
          write-verbose "Release:`n$($release|out-string)"
          $releaseFromJson = $release|convertFrom-json -errorAction ignore
          $tagName = $releaseFromJson.tagName
          $releaseName = $releaseFromJson.name
          $isPreRelease = $releaseFromJson.isPrerelease
          write-verbose "tagName: $($tagName) releaseName: $($releaseName) isPreRelease: $($isPreRelease)"
          Write-Output "tag_name=$tagName" >> $env:GITHUB_OUTPUT
          Write-Output "release_name=$releaseName" >> $env:GITHUB_OUTPUT
          Write-Output "release_isPreRelease=$isPreRelease" >> $env:GITHUB_OUTPUT

      - name: Install dependencies
        shell: pwsh
        run: |
          $VerbosePreference = 'Continue'
          Install-Module -Name Microsoft.PowerShell.PSResourceGet -Force -SkipPublisherCheck
          $moduleList = @('Microsoft.PowerShell.PSResourceGet')
          import-module $moduleList
          get-module $moduleList|Select-object Name,@{name='version';expression={if($_.PrivateData.PSData.Prerelease){"$($_.Version)-$($_.PrivateData.PSData.Prerelease)"}else{"$($_.Version)"}}}|Format-Table

      - name: Register Repository
        shell: pwsh
        id: repoSetup
        if: success()  
        run: |
          $VerbosePreference = 'Continue'
          $repoUrl = "https://nuget.pkg.github.com/$($env:GITHUB_REPOSITORY_OWNER)/index.json"
          write-verbose "Got repoUrl: $repoUrl"
          $repositorySplat = @{
            uri = $repoUrl
            trusted = $true
            name = 'myGHPackages'
          }
          register-psresourcerepository @repositorySplat
          write-verbose "Repositories:`n $(get-psresourceRepository|select name,uri,trusted|format-list|out-string)"

      - name: Install Latest Module And Publish to Gallery
        shell: pwsh
        id: moduleInstall
        env:
          GH_TOKEN: ${{ github.token }}
          PSGalleryToken: ${{ secrets.PSGALLERY }}
          isPreRelease: ${{ steps.get_release.outputs.release_isPreRelease }}
          tagName: ${{ steps.get_release.outputs.tag_name }}
        if: success()  
        run: |
          $VerbosePreference = 'Continue'
          $isPreRelease = $env:isPreRelease
          if(!(test-path .\moduleForgeConfig.xml)){
            throw 'Error reading ModuleForge Config'
          }
          $config = import-clixml .\moduleForgeConfig.xml
          $moduleName = $config.moduleName
          write-verbose "ModuleName: $moduleName"
          $credential = New-Object System.Management.Automation.PSCredential("githubActions", (ConvertTo-SecureString $env:GH_TOKEN -AsPlainText -Force))
          $versionString = $env:tagName
          write-verbose "Version from Tag: $versionString"
          $version = $versionString.substring(1)
          $semver = [semver]::New($version)
          write-verbose "VersionConvert : $semver"
          $fetchSplat = @{
            Repository = 'myGHPackages'
            name = $moduleName
            credential = $credential
            version = $semver
          }
          $latestRelease = find-psresource @fetchSplat
          write-verbose "latestRelease: $($latestRelease|format-list|out-string)"
          if($latestRelease)
          {
            $latestRelease|install-psresource -credential $credential
          }else{
            write-warning 'No module found'
          }
          $moduleFound = get-module $moduleName -listAvailable
          if($moduleFound)
          {
            write-verbose "ModuleFound:`n$($moduleFound|out-string)"
          }else{
            throw 'Module failed install'
          }
          write-verbose 'Push Package to PSGallery'
          $publishSplat = @{
            repository = 'PSGallery'
            APIKey = $env:PSGalleryToken
            Path = $moduleFound.moduleBase
          }
          publish-psResource @publishSplat
```

## Hints and Extras

- If you wish to verify your workflow is set up correctly without publishing, you can temporarily comment out the `publish-psResource` line and inspect the verbose logs from the install step