$registerSplat = @{
    Name = 'DomainPlatformEngineering'
    URL = 'https://nuget.pkg.github.com/domain-platform-engineering/index.json'
    Trusted = $true
}

Register-PSResourceRepository @registerSplat

#$ghcred = get-secret ghub_repository
$cred = get-credential 


Find-PSResource -Repository DomainPlatformEngineering -Name * -Credential $cred

unregister-PSResourceRepository DomainPlatformEngineering

<# Looks like the v2 search endpoint is NOT SUPPORTED at all, which makes this dead in the water 
{
      "version": "3.0.0-beta.1",
      "resources": [
        {
          "@id": "https://nuget.pkg.github.com/domain-platform-engineering/download",
          "@type": "PackageBaseAddress/3.0.0",
          "comment": "Get package content (.nupkg)."
        },
        {
          "@id": "https://nuget.pkg.github.com/domain-platform-engineering/query",
          "@type": "SearchQueryService",
          "comment": "Filter and search for packages by keyword."
        },
        {
          "@id": "https://nuget.pkg.github.com/domain-platform-engineering/query",
          "@type": "SearchQueryService/3.0.0-beta",
          "comment": "Filter and search for packages by keyword."
        },
        {
          "@id": "https://nuget.pkg.github.com/domain-platform-engineering/query",
          "@type": "SearchQueryService/3.0.0-rc",
          "comment": "Filter and search for packages by keyword."
        },
        {
          "@id": "https://nuget.pkg.github.com/domain-platform-engineering",
          "@type": "PackagePublish/2.0.0",
          "comment": "Push and delete (or unlist) packages."
        },
        {
          "@id": "https://nuget.pkg.github.com/domain-platform-engineering",
          "@type": "RegistrationsBaseUrl",
          "comment": "Get package metadata."
        },
        {
          "@id": "https://nuget.pkg.github.com/domain-platform-engineering",
          "@type": "RegistrationsBaseUrl/3.0.0-beta",
          "comment": "Get package metadata."
        },
        {
          "@id": "https://nuget.pkg.github.com/domain-platform-engineering",
          "@type": "RegistrationsBaseUrl/3.0.0-rc",
          "comment": "Get package metadata."
        }
      ]
    }
#>