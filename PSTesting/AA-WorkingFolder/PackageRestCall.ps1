


$filePath = "path\to\your\nuspecfile.nuspec"
$fileContent = Get-Content -Path $filePath -Raw
$base64FileContent = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($fileContent))

$owner = "your-github-username"
$repo = "your-repository-name"
$path = "path/in/repository/nuspecfile.nuspec"
$branch = "main"
$message = "Add nuspec file"
$token = "your-personal-access-token"

$headers = @{
    "Authorization" = "token $token"
    "Accept" = "application/vnd.github.v3+json"
}

$body = @{
    "message" = $message
    "content" = $base64FileContent
    "branch" = $branch
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo/contents/$path" -Method Put -Body $body -Headers $headers


<#
name: Publish and Tag Release

on:
  push:
    branches:
      - main  # Trigger the workflow on push or pull request to the main branch

jobs:
  publish:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v2

    - name: Set up PowerShell
      uses: actions/setup-powershell@v1

    - name: Publish package
      run: |
        # Your PowerShell commands to publish the package go here
        # For example:
        # Publish-PSResource -Path path/to/your/module -NuGetApiKey ${{ secrets.NUGET_API_KEY }}

    - name: Create Release
      id: create_release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }} # This token is provided by Actions, you do not need to create your own token
      with:
        tag_name: ${{ github.ref }}
        release_name: Release ${{ github.ref }}
        draft: false
        prerelease: false


#>