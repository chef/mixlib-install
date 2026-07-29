# PSScriptAnalyzer settings for the generated install.ps1
#
# The powershell generator (lib/mixlib/install/generator/powershell) targets
# Windows PowerShell versions as old as 2.0 (no Get-CimInstance) and is meant
# to print progress to an interactive console. The rules below are excluded
# because they either flag intentional compatibility/UX choices or produce
# false positives against this script's structure.
@{
    ExcludeRules = @(
        # Write-Host is used throughout to print install progress to the
        # console, which is the whole point of an interactive bootstrap
        # script. Write-Output would change the function's return value.
        'PSAvoidUsingWriteHost',

        # Get-WMIQuery already prefers Get-CimInstance and only falls back to
        # Get-WmiObject when CIM isn't available (older PowerShell/Windows),
        # so the WMI cmdlet usage is an intentional compatibility fallback.
        'PSAvoidUsingWMICmdlet',

        # New-Uri only builds a System.Uri object; it never changes system
        # state, so it doesn't need to support ShouldProcess despite the verb.
        'PSUseShouldProcessForStateChangingFunctions',

        # $hash is the accumulator variable threaded through a
        # ForEach-Object -Begin/-Process/-End pipeline; the analyzer can't
        # see the -End block reference across the split script blocks.
        'PSUseDeclaredVarsMoreThanAssignments',

        # Test-Fips and Get-ProjectMetadata are not linguistic plurals
        # ("Fips" is an acronym, "Metadata" isn't pluralized); there's no
        # sensible singular rename for either.
        'PSUseSingularNouns'
    )
}
