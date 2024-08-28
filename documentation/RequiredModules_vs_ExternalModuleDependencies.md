# Required Modules vs External Module Dependencies

The Module Manifest has 2 ways to handle module dependencies; `RequiredModules`, and `ExternalModuleDependencies`. How these work is quite different, and what you choose to use depends, ultimately, on what you are trying to achieve.

`RequiredModules` will only really work if the publishing repository (E.g. PSGallery) has the module already. If it doesn't, your `publish-psresource` or `publish-module` command will fail, as it checks for the dependent modules before it pushes your module. The benefit of this approach is that it will also install any module dependencies for the user when you run `install-psresource` or `install-module`.

I find this a little too rigid in practice, so it's best used if you need a specific version of a module that you want to pin to yours, and you have made sure it's in the resource repository already, and it is unlikely to be removed by the owner.

I find that using `ExternalModuleDependencies` is more flexible, it put's the onous of installing the dependency back on to the user. Then in order to make it clear, I'll often put something like this in the begin block of my functions that have a dependency:

```Powershell
Begin {
#...
$requiredModules = @(
    'Microsoft.Graph.Authentication'
    'Microsoft.Graph.Beta.DeviceManagement'
    'Microsoft.Graph.Users'
)
$requiredModules.foreach{
    if((-not (get-module $_ -listavailable)))
    {
        throw "Module $_ not found. Please install it first"
    }else{
        write-verbose "Found module: $_"
    }
}
#...
}
```

And if I have lots of functions that might have such dependencies, I tend to make a private function that just does this, and call that in the begin block.

```Powershell
function test-moduleDependencies
#...
$requiredModules = @(
    'Microsoft.Graph.Authentication'
    'Microsoft.Graph.Beta.DeviceManagement'
    'Microsoft.Graph.Users'
)
$requiredModules.foreach{
    if((-not (get-module $_ -listavailable)))
    {
        throw "Module $_ not found. Please install it first"
    }else{
        write-verbose "Found module: $_"
    }
    return $true
}
#...
```

This way, I'm making it clear what's gone wrong, but I'm not dictating how the module was installed, or what version is running.

It also means I'm not republishing other peoples modules to my private repository, maintaining the repository trust setting, and avoiding any license concerns.

Ultimately, try both ways, and find something that works for you, your organisation and your specific module.

If you want more details, check out [this on reddit](https://www.reddit.com/r/PowerShell/comments/7lt6mz/module_manifests_requiredmodules_vs/) and [in this linked github issue](https://github.com/OneGet/oneget/issues/164)

 > So a brief bit of googling turned this up. It seems that, on some level, RequiredModules should be used for all internal and external modules that your module depends on. ExternalModuleDepencies apparently identifies which modules you're not including in the package itself and must also be obtained somehow/somewhere. So you'd list internal dependencies once in RequiredModules and external dependencies twice (once with name and version in RequiredModules and once by name only in ExternalModuleDependencies).

I'm not sure I agree with the approach suggested, but it does help frame the thought-process.