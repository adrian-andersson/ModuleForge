class ValidateStringOrHashtableAttribute : System.Management.Automation.ValidateArgumentsAttribute
{
    [void] Validate([object] $arguments, [System.Management.Automation.EngineIntrinsics] $engineIntrinsics)
    {
        # Check if arguments is an array
        if ($arguments -is [Array])
        {
            foreach ($arg in $arguments)
            {
                # Check if each element in the array is either a string or a hashtable
                if (-not ($arg -is [string] -or $arg -is [hashtable]))
                {
                    throw [System.ArgumentException]::new("Input types need to be either a string or a hashtable.")
                }
            }
        }
        else
        {
            throw [System.ArgumentException]::new("Input needs to be an array.")
        }
    }
}
