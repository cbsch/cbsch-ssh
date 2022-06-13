Get-ChildItem -Recurse $PSScriptRoot/../script/*.ps1 | ForEach-Object {
    . $_
}