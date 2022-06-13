$script:SshTabSettings = New-Object PSObject -Property @{
    EnableLogging = $false
    LogPath = Join-Path ([System.IO.Path]::GetTempPath()) ssh_tabexp.log
}

# $shortParams = "46AaCfGgKkMNnqsTtVvXxYyBbcDEeFIiJLlmOopQRSWw" -split "" `
# | Select-Object -Skip 1 `
# | Select-Object -SkipLast 1 `
# | Join-String -Separator "|"

Function WriteTabExpLog([string] $Message) {
    if (!$script:SshTabSettings.EnableLogging) { return }
    $timestamp = Get-Date -Format HH:mm:ss
    "[$timestamp] $Message" | Out-File -Append $script:SshTabSettings.LogPath
}

Function Expand-SshCommand {
    Param(
        [string]$Command
    )

    SShTabExpansionInternal $Command
}

Function Invoke-HostParser {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
    Param(
        [Parameter()][string]$ConfigPath = (Resolve-Path (Join-Path -Path "~" ".ssh" "config")),
        [Parameter()][string]$RootPath = (Resolve-Path (Join-Path -Path "~" ".ssh"))
    )
    Get-Content -Path $ConfigPath | % {
        switch -Regex ($_) {
            "^Host (?!\*)(?<host>.*)$" {
                $matches["host"] | Write-Output
            }
            "^Include (?<include>.*)$" {
                Get-ChildItem (Join-Path $RootPath $matches["include"]) `
                | Select-Object -ExpandProperty FullName `
                | % { Invoke-HostParser -ConfigPath $_ } `
                | Write-Output
            }
        }
    }
}

Function GetHosts {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
    Param([string]$HostName)

    Invoke-HostParser | ? { $_ -like "$HostName*"}
}

Function SShTabExpansionInternal {
    Param(
        [string]$LastBlock
    )

    switch -regex ($lastBlock -replace "^s(sh|cp) ","") {
        "^(?<host>.*)$" {
            GetHosts $matches["host"]
        }
        # "^.* -(?<shortparam>\S*)$" {
        #     expandShortParams $shortGitParams $matches['cmd'] $matches['shortparam']
        # }
    }
}

$argumentCompleter = {
    Param(
        [string]$WordToComplete,
        [System.Management.Automation.Language.CommandAst]$CommandAst,
        [int]$CursorPosition
    )

    $WordToComplete | Out-Null

    $padLength = $CursorPosition - $CommandAst.Extent.StartOffset
    $textToComplete = $CommandAst.ToString().PadRight($padLength, ' ').Substring(0, $padLength)
    if ($EnableProxyFunctionExpansion) {
        $textToComplete = Expand-GitProxyFunction($textToComplete)
    }

    WriteTabExpLog "Expand: command: '$($CommandAst.Extent.Text)', padded: '$textToComplete', padlen: $padLength"
    Expand-SshCommand $textToComplete
}

Microsoft.PowerShell.Core\Register-ArgumentCompleter -CommandName "ssh" -Native -ScriptBlock $argumentCompleter
Microsoft.PowerShell.Core\Register-ArgumentCompleter -CommandName "scp" -Native -ScriptBlock $argumentCompleter
