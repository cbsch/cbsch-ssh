$manifestPath = Get-ChildItem $PSScriptRoot/../*.psd1 | Select-Object -First 1

$manifest = Get-Content $manifestPath -Raw -Encoding utf8
if ($manifest -match "ModuleVersion = '(.*)'") {
    $version = [Version]::new($matches[1])
    $newVersion = "{0}.{1}.{2}" -f $version.Major,$version.Minor,(1 + [int]$version.Build)

    [Regex]::Replace($manifest, "ModuleVersion = '(.*)'", "ModuleVersion = '$newVersion'")
    | Set-Content -Path $manifestPath -Encoding utf8 -NoNewline

    git add $manifestPath
    git commit -m "Automatically bumped build number"
}

Publish-Module -Name $manifestPath `
    -NuGetApiKey (Get-StoredCredential PSPublishKey).GetNetworkCredential().Password