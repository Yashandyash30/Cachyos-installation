Ran command: `$PSVersionTable; Get-Module PSReadLine -ListAvailable | Select-Object Name, Version, Path; $PROFILE`
Ran command: `Test-Path $PROFILE; if (Test-Path $PROFILE) { Get-Content $PROFILE } else { "Profile does not exist yet" }`
Ran command: `Get-Module -ListAvailable posh-git, Terminal-Icons, CompletionPredictor; Get-Command oh-my-posh, starship, fzf, winget -ErrorAction SilentlyContinue | Select-Object Name, Source`
Listed directory debug
Ran command: `Get-PSReadLineOption | Select-Object EditMode, HistoryNoDuplicates, PredictionSource, PredictionViewStyle, Colors`
Ran command: `[enum]::GetNames([Microsoft.PowerShell.PredictionSource]); [enum]::GetNames([Microsoft.PowerShell.PredictionViewStyle])`
Ran command: `Import-Module PSReadLine; [enum]::GetNames([Microsoft.PowerShell.PSReadLine.PredictionSource]); [enum]::GetNames([Microsoft.PowerShell.PSReadLine.PredictionViewStyle])`
Ran command: `Import-Module PSReadLine; (Get-Command Set-PSReadLineOption).Parameters['PredictionSource'].ParameterType.FullName`
Ran command: `(Get-Command Set-PSReadLineOption).Parameters['PredictionSource'].ParameterType.GetEnumNames(); (Get-Command Set-PSReadLineOption).Parameters['PredictionViewStyle'].ParameterType.GetEnumNames()`
Ran command: `Find-Module -Name CompletionPredictor, Terminal-Icons, posh-git -ErrorAction SilentlyContinue | Select-Object Name, Version, Description`
Used tool: manage_task
Ran command: `Get-ChildItem "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal*\LocalState\settings.json" -ErrorAction SilentlyContinue | Select-Object FullName`
Ran command: `$wtSettings = Get-Content "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" -Raw | ConvertFrom-Json; [PSCustomObject]@{ defaultProfile = $wtSettings.defaultProfile; profileNames = $wtSettings.profiles.list | ForEach-Object { "$($_.name) ($($_.guid))" } }`
Ran command: `$wtSettings = Get-Content "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" -Raw | ConvertFrom-Json; $wtSettings.profiles.list | Select-Object name, guid, commandline, source`
Ran command: `Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts', 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts' -ErrorAction SilentlyContinue | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -match 'Nerd|Cascadia|Meslo|JetBrains' } | Select-Object Name`
Ran command: `Get-ChildItem -Path "C:\Windows\Fonts", "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'Cascadia|Nerd|JetBrains|Meslo' } | Select-Object Name`
Ran command: `[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null; (New-Object System.Drawing.Text.InstalledFontCollection).Families | Where-Object { $_.Name -match 'Cascadia|Consolas|Code|Mono' } | Select-Object Name`
Ran command: `Get-InstalledModule -ErrorAction SilentlyContinue`
Ran command: `Get-Command Install-PSResource, Install-Module -ErrorAction SilentlyContinue | Select-Object Name, Source`
Ran command: `Install-PSResource -Name CompletionPredictor, Terminal-Icons, posh-git -Scope CurrentUser -TrustRepository -ErrorAction Stop; Get-Module CompletionPredictor, Terminal-Icons, posh-git -ListAvailable | Select-Object Name, Version, Path`
Ran command: `Import-Module PSReadLine
Import-Module CompletionPredictor
Import-Module Terminal-Icons
Import-Module posh-git
Get-PSSubsystem -Kind CommandPredictor | Select-Object -ExpandProperty ImplementedBy
`
Ran command: `Get-PSSubsystem -Kind CommandPredictor`
Ran command: `Import-Module CompletionPredictor; (Get-PSSubsystem -Kind CommandPredictor).Implementations`
Used tool: manage_task
Used tool: manage_task
Used tool: manage_task
Ran command: `winget complete --help`
Ran command: `Get-Command dotnet, gh -ErrorAction SilentlyContinue | Select-Object Name, Source`
Ran command: `$path = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"; Get-Content $path | Select-Object -First 30`
Ran command: `$path = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"; ($json = Get-Content $path -Raw | ConvertFrom-Json).profiles.defaults`
Ran command: `oh-my-posh --version`
Ran command: `Get-ChildItem -Path "$env:USERPROFILE\.posh*", "$env:LOCALAPPDATA\Programs\oh-my-posh\themes" -ErrorAction SilentlyContinue | Select-Object FullName`
Ran command: `$poshThemes = "$env:LOCALAPPDATA\Programs\oh-my-posh\themes"; if (Test-Path $poshThemes) { (Get-ChildItem $poshThemes).Count } else { "No themes dir in localappdata" }; (Get-Command oh-my-posh).Source`
Ran command: `$env:POSH_THEMES_PATH`
Ran command: `oh-my-posh init pwsh`
Ran command: `Get-ChildItem "C:\Users\void\AppData\Local\Packages\ohmyposh.cli_96v55e8n804z4\LocalCache\Local\oh-my-posh\themes" -ErrorAction SilentlyContinue | Select-Object -First 5 Name`
Ran command: `oh-my-posh config --help`
Ran command: `pwsh -NoProfile -Command "
Import-Module PSReadLine
Import-Module CompletionPredictor -ErrorAction SilentlyContinue
Import-Module Terminal-Icons -ErrorAction SilentlyContinue
Import-Module posh-git -ErrorAction SilentlyContinue

Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -MaximumHistoryCount 20000
Set-PSReadLineOption -HistoryNoDuplicates:`$true
Set-PSReadLineOption -BellStyle None

Set-PSReadLineOption -Colors @{
    InlinePrediction = \"`e[38;5;244m\"
    ListPrediction   = \"`e[36m\"
    Command          = \"`e[93m\"
    Parameter        = \"`e[96m\"
    Operator         = \"`e[95m\"
    Variable         = \"`e[92m\"
    String           = \"`e[32m\"
    Number           = \"`e[94m\"
    Member           = \"`e[97m\"
    Error            = \"`e[91m\"
}

Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Ctrl+Space' -Function MenuComplete
Set-PSReadLineKeyHandler -Key F2 -Function SwitchPredictionView
Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo
Set-PSReadLineKeyHandler -Chord 'Shift+Enter' -Function AddLine
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteCharOrExit
Set-PSReadLineKeyHandler -Chord 'Ctrl+Backspace' -Function BackwardKillWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+Delete' -Function KillWord

Write-Output 'PSReadLine config verified successfully!'
"`
Ran command: `pwsh -NoProfile -Command "Import-Module PSReadLine; Set-PSReadLineOption -Colors @{ InlinePrediction = [ConsoleColor]::DarkGray; Command = [ConsoleColor]::Yellow; Parameter = [ConsoleColor]::Cyan; Operator = [ConsoleColor]::Magenta; Variable = [ConsoleColor]::Green; String = [ConsoleColor]::DarkGreen; Number = [ConsoleColor]::Blue; Error = [ConsoleColor]::Red }; 'OK'"`
Ran command: `pwsh -NoProfile -Command "Import-Module PSReadLine; Set-PSReadLineOption -Colors @{ InlinePrediction = 'DarkGray'; ListPrediction = 'Cyan'; Command = 'Yellow'; Parameter = 'Cyan' }; 'OK'"`
Ran command: `pwsh -NoProfile -Command "Import-Module PSReadLine; Set-PSReadLineKeyHandler -Key F2 -Function SwitchPredictionView; Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward; Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward; Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete; 'Keybindings OK'"`
Ran command: `pwsh -NoProfile -Command "
Import-Module PSReadLine
Set-PSReadLineKeyHandler -Chord 'Ctrl+Space' -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo
Set-PSReadLineKeyHandler -Chord 'Shift+Enter' -Function AddLine
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteCharOrExit
Set-PSReadLineKeyHandler -Chord 'Ctrl+Backspace' -Function BackwardKillWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+Delete' -Function KillWord
'Chord bindings OK'
"`
Ran command: `pwsh -NoProfile -Command "Import-Module PSReadLine; Set-PSReadLineKeyHandler -Chord 'Ctrl+Spacebar' -Function MenuComplete; 'Spacebar OK'"`
Ran command: `pwsh -NoProfile -Command "Import-Module PSReadLine; Get-PSReadLineKeyHandler -Bound -Unbound | Where-Object { `$_.Function -match 'Prediction|Suggestion' } | Select-Object Key, Function, Description"`
Ran command: `pwsh -NoProfile -Command "Import-Module PSReadLine; Get-PSReadLineKeyHandler -Bound | Where-Object { `$_.Key -match 'RightArrow' } | Select-Object Key, Function, Description"`
Ran command: `pwsh -NoProfile -Command "
Import-Module PSReadLine
Set-PSReadLineKeyHandler -Chord 'Ctrl+f' -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Chord 'Alt+f' -Function AcceptNextSuggestionWord
'Bindings test passed'
"`
Ran command: `pwsh -NoProfile -Command "
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param(`$wordToComplete, `$commandAst, `$cursorPosition)
    [Console]::InputEncoding = [Console]::OutputEncoding = `$OutputEncoding = [System.Text.Utf8Encoding]::new()
    `$Local:word = `$wordToComplete.Replace('\"', '\"\"')
    `$Local:ast = `$commandAst.ToString().Replace('\"', '\"\"')
    winget complete --word=\"`$Local:word\" --commandline \"`$Local:ast\" --position `$cursorPosition | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new(`$_, `$_, 'ParameterValue', `$_)
    }
}
'winget completer registered successfully'
"`
Ran command: `pwsh -NoProfile -Command "Import-Module Terminal-Icons; Get-ChildItem -Path 'c:\Drive_E\debug' | Select-Object -First 3"`
Ran command: `pwsh -NoProfile -Command "Import-Module posh-git; 'posh-git loaded'"`
Ran command: `pwsh -NoProfile -Command "
Measure-Command {
    Import-Module PSReadLine
    Import-Module CompletionPredictor
    Import-Module Terminal-Icons
    Import-Module posh-git
} | Select-Object TotalMilliseconds
"`
Ran command: `pwsh -NoProfile -Command "
foreach (`$m in @('PSReadLine', 'CompletionPredictor', 'Terminal-Icons', 'posh-git')) {
    `$time = Measure-Command { Import-Module `$m }
    [PSCustomObject]@{ Module = `$m; Milliseconds = [math]::Round(`$time.TotalMilliseconds, 1) }
}
"`
Ran command: `Get-Command sudo, gsudo -ErrorAction SilentlyContinue | Select-Object Name, Source`
Ran command: `Copy-Item $PROFILE "$PROFILE.bak" -Force; Test-Path "$PROFILE.bak"`
Ran command: `pwsh -NoProfile -Command "Import-Module PSReadLine; Set-PSReadLineOption -Colors @{ InlinePrediction = \"`e[38;5;244m\" }; 'Valid!'"`
Ran command: `$testFile = "$env:TEMP\test_psreadline.ps1"
@'
Import-Module PSReadLine
Set-PSReadLineOption -Colors @{
    InlinePrediction = "$([char]0x1b)[38;5;244m"
    ListPrediction   = "Cyan"
    Command          = "Yellow"
    Parameter        = "Cyan"
    Operator         = "Magenta"
    Variable         = "Green"
    String           = "DarkGreen"
    Number           = "DarkBlue"
    Member           = "White"
    Error            = "Red"
}
Write-Output "PSReadLine Colors Loaded Successfully!"
'@ | Set-Content -Path $testFile -Encoding utf8
pwsh -NoProfile -File $testFile
Remove-Item $testFile
`
Ran command: `$testFile = "$env:TEMP\test_full_profile.ps1"
@'
# ====================================================================
# PowerShell 7 + PSReadLine Native Windows Power Profile
# ====================================================================

# 1. Modules
Import-Module PSReadLine
Import-Module CompletionPredictor -ErrorAction SilentlyContinue
Import-Module Terminal-Icons -ErrorAction SilentlyContinue
Import-Module posh-git -ErrorAction SilentlyContinue

# 2. Predictive IntelliSense & PSReadLine Configuration
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -MaximumHistoryCount 20000
Set-PSReadLineOption -HistoryNoDuplicates:$true
Set-PSReadLineOption -BellStyle None

# 3. Syntax Highlighting & Prediction Colors
Set-PSReadLineOption -Colors @{
    InlinePrediction = "$([char]0x1b)[38;5;244m"
    ListPrediction   = "Cyan"
    Command          = "Yellow"
    Parameter        = "Cyan"
    Operator         = "Magenta"
    Variable         = "Green"
    String           = "DarkGreen"
    Number           = "DarkBlue"
    Member           = "White"
    Error            = "Red"
}

# 4. Keybindings
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Ctrl+Spacebar' -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Ctrl+f' -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Chord 'Alt+f' -Function AcceptNextSuggestionWord
Set-PSReadLineKeyHandler -Key F2 -Function SwitchPredictionView
Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo
Set-PSReadLineKeyHandler -Chord 'Shift+Enter' -Function AddLine
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteCharOrExit
Set-PSReadLineKeyHandler -Chord 'Ctrl+Backspace' -Function BackwardKillWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+Delete' -Function KillWord

# 5. Native Windows Tooling Completers
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
        $Local:word = $wordToComplete.Replace('"', '""')
        $Local:ast = $commandAst.ToString().Replace('"', '""')
        winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
}

if (Get-Command dotnet -ErrorAction SilentlyContinue) {
    Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        dotnet complete --position $cursorPosition "$commandAst" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
}

# 6. Quality of Life Utilities & Aliases
function which ($command) { Get-Command -Name $command -ErrorAction SilentlyContinue }
function touch ($file) {
    if (Test-Path $file) {
        (Get-Item $file).LastWriteTime = Get-Date
    } else {
        New-Item -ItemType File -Path $file -Force | Out-Null
    }
}
function reload-profile {
    & $PROFILE
    Write-Host "PowerShell profile reloaded successfully!" -ForegroundColor Green
}

Write-Output "Test script executed without errors!"
'@ | Set-Content -Path $testFile -Encoding utf8

pwsh -NoProfile -File $testFile
Remove-Item $testFile
`
Ran command: `$testFile = "$env:TEMP\test_guard.ps1"
@'
Import-Module PSReadLine
try {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin -ErrorAction SilentlyContinue
    Set-PSReadLineOption -PredictionViewStyle InlineView -ErrorAction SilentlyContinue
} catch {}
Write-Output "Clean run!"
'@ | Set-Content -Path $testFile -Encoding utf8

pwsh -NoProfile -File $testFile
Remove-Item $testFile
`
Ran command: `$testFile = "$env:TEMP\test_guard_keyhandler.ps1"
@'
Import-Module PSReadLine
try {
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Chord 'Ctrl+Spacebar' -Function MenuComplete -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Chord 'Ctrl+f' -Function AcceptSuggestion -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Chord 'Alt+f' -Function AcceptNextSuggestionWord -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key F2 -Function SwitchPredictionView -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Chord 'Shift+Enter' -Function AddLine -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteCharOrExit -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Chord 'Ctrl+Backspace' -Function BackwardKillWord -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Chord 'Ctrl+Delete' -Function KillWord -ErrorAction SilentlyContinue
} catch {}
Write-Output "Keyhandlers clean!"
'@ | Set-Content -Path $testFile -Encoding utf8

pwsh -NoProfile -File $testFile
Remove-Item $testFile
`
Ran command: `Get-Content "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" -Raw`
Ran command: `$wtPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"; Copy-Item $wtPath "$wtPath.bak" -Force; Test-Path "$wtPath.bak"`
Ran command: `$wtPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$wt = Get-Content $wtPath -Raw | ConvertFrom-Json
$wt.defaultProfile = "{574e775e-4f2a-5b96-ac1e-a2962a402336}"
if (-not $wt.profiles.defaults.font) {
    $wt.profiles.defaults | Add-Member -MemberType NoteProperty -Name "font" -Value ([PSCustomObject]@{ face = "Cascadia Code" }) -Force
} else {
    $wt.profiles.defaults.font.face = "Cascadia Code"
}
$wt | ConvertTo-Json -Depth 10 | Set-Content $wtPath -Encoding utf8
"Windows Terminal default profile updated to PowerShell 7!"
`
Ran command: `$profileContent = @'
# ====================================================================
# PowerShell 7 (pwsh) + PSReadLine — Native Windows Power Setup
# ====================================================================

# --------------------------------------------------------------------
# 1. Companion Modules
# --------------------------------------------------------------------
Import-Module PSReadLine
Import-Module CompletionPredictor -ErrorAction SilentlyContinue
Import-Module posh-git -ErrorAction SilentlyContinue
Import-Module Terminal-Icons -ErrorAction SilentlyContinue

# --------------------------------------------------------------------
# 2. PSReadLine Predictive IntelliSense & General Options
# --------------------------------------------------------------------
try {
    # Predictive IntelliSense combining command history & registered plugins (CompletionPredictor)
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin -ErrorAction SilentlyContinue
    Set-PSReadLineOption -PredictionViewStyle InlineView -ErrorAction SilentlyContinue

    # Smart History navigation: cursor moves to the end of the line on recall
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd

    # Increase command history size & avoid recording consecutive duplicates
    Set-PSReadLineOption -MaximumHistoryCount 20000
    Set-PSReadLineOption -HistoryNoDuplicates:$true

    # Disable terminal beep / bell
    Set-PSReadLineOption -BellStyle None
} catch {}

# --------------------------------------------------------------------
# 3. PSReadLine High-Contrast & Ghost-Text Colors
# --------------------------------------------------------------------
try {
    Set-PSReadLineOption -Colors @{
        InlinePrediction = "$([char]0x1b)[38;5;244m" # Subtle muted grey ghost text
        ListPrediction   = "Cyan"                   # Highlighted predictor items in list view
        Command          = "Yellow"                 # Commands
        Parameter        = "Cyan"                   # Cmdlet/CLI flags
        Operator         = "Magenta"                # Operators
        Variable         = "Green"                  # Variables
        String           = "DarkGreen"              # Quoted strings
        Number           = "DarkBlue"               # Numeric literals
        Member           = "White"                  # Object properties/methods
        Error            = "Red"                    # Syntax errors
    }
} catch {}

# --------------------------------------------------------------------
# 4. Enhanced Keybindings
# --------------------------------------------------------------------
try {
    # Prefix-matching history search: Type 'git' and hit UpArrow to cycle past git commands
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

    # Interactive Tab completion menu (navigable with arrow keys)
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Chord 'Ctrl+Spacebar' -Function MenuComplete

    # Predictive suggestion acceptance
    Set-PSReadLineKeyHandler -Chord 'Ctrl+f' -Function AcceptSuggestion
    Set-PSReadLineKeyHandler -Chord 'Alt+f' -Function AcceptNextSuggestionWord

    # Dynamic toggle between Inline ghost text and multi-line ListView dropdown
    # (Press F2 to toggle between Inline and List view!)
    Set-PSReadLineKeyHandler -Key F2 -Function SwitchPredictionView
    Set-PSReadLineKeyHandler -Key F4 -Function ShowFullPredictionTooltip

    # Shell productivity shortcuts
    Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
    Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo
    Set-PSReadLineKeyHandler -Chord 'Shift+Enter' -Function AddLine
    Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteCharOrExit
    Set-PSReadLineKeyHandler -Chord 'Ctrl+Backspace' -Function BackwardKillWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+Delete' -Function KillWord
} catch {}

# --------------------------------------------------------------------
# 5. Native Windows Tooling Completers
# --------------------------------------------------------------------
# Windows Package Manager (winget) Autocompletion
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
        $Local:word = $wordToComplete.Replace('"', '""')
        $Local:ast = $commandAst.ToString().Replace('"', '""')
        winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
}

# .NET CLI Autocompletion
if (Get-Command dotnet -ErrorAction SilentlyContinue) {
    Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        dotnet complete --position $cursorPosition "$commandAst" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
}

# --------------------------------------------------------------------
# 6. Quality of Life Aliases & Helpers
# --------------------------------------------------------------------
function which ($command) {
    Get-Command -Name $command -ErrorAction SilentlyContinue
}

function touch ($path) {
    if (Test-Path $path) {
        (Get-Item $path).LastWriteTime = Get-Date
    } else {
        New-Item -ItemType File -Path $path -Force | Out-Null
    }
}

function reload-profile {
    & $PROFILE
    Write-Host "Profile reloaded successfully!" -ForegroundColor Green
}

function admin {
    Start-Process pwsh -Verb RunAs
}

# --------------------------------------------------------------------
# 7. User Custom Functions & Network Tools
# --------------------------------------------------------------------
# Wake-on-LAN
function wakepc {
    # CachyOS PC MAC address
    $mac = "f0:4e:a4:37:91:66"
    $macBytes = $mac -split '[:-]' | ForEach-Object { [byte]('0x' + $_) }
    $magicPacket = [byte[]](,0xFF * 6) + ($macBytes * 16)
    $udpClient = New-Object System.Net.Sockets.UdpClient
    $udpClient.EnableBroadcast = $true
    $udpClient.Connect(([System.Net.IPAddress]::Broadcast), 9)
    $udpClient.Send($magicPacket, $magicPacket.Length) | Out-Null
    $udpClient.Close()
    Write-Host "Wake-on-LAN packet sent!" -ForegroundColor Green
}

# SSH to PC (with auto-wake)
function sshpc {
    $ping = Test-Connection -ComputerName 100.117.73.75 -Count 1 -Quiet
    if (-not $ping) {
        Write-Host "PC is offline. Sending Wake-on-LAN..." -ForegroundColor Yellow
        wakepc
        Write-Host "Waiting 30 seconds for PC to boot and connect to Tailscale..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
    }
    Write-Host "Connecting to PC..." -ForegroundColor Cyan
    ssh void@100.117.73.75
}

# Phone Battery Check
function phonebattery {
    Write-Host "Querying voidphone..." -ForegroundColor Cyan
    $json = ssh -p 8022 u0_a183@100.103.187.97 "termux-battery-status"
    $bat = $json | ConvertFrom-Json
    Write-Host "Battery Level: $($bat.percentage)%"
    Write-Host "Status: $($bat.status)"
}

# Phone SSH
function sshphone {
    Write-Host "Connecting to voidphone..." -ForegroundColor Cyan
    ssh -p 8022 u0_a183@100.103.187.97
}

# Stream Recovery
function fixstream {
    Write-Host "Waking monitors..." -ForegroundColor Cyan
    ssh void@100.117.73.75 "ddcutil -d 1 setvcp 0xd6 0x01 || true; ddcutil -d 2 setvcp 0xd6 0x01 || true"
    Write-Host "Restarting Sunshine..." -ForegroundColor Cyan
    ssh void@100.117.73.75 "systemctl --user restart sunshine"
    Write-Host "Recovery complete." -ForegroundColor Green
}

function checkmonitors {
    Write-Host "Querying physical monitor power states..." -ForegroundColor Cyan
    ssh void@100.117.73.75 "ddcutil -d 1 getvcp d6 || true; ddcutil -d 2 getvcp d6 || true"
}
'@

Set-Content -Path $PROFILE -Value $profileContent -Encoding utf8
"Profile saved to $PROFILE"
`
Ran command: `pwsh -Command ". `$PROFILE; 'Profile loaded successfully without errors!'"`
Used tool: manage_task
Used tool: manage_task
Ran command: `winget search "Cascadia Code NF" --accept-source-agreements`
Used tool: manage_task
Used tool: manage_task
Ran command: `oh-my-posh font --help`
Used tool: manage_task
Used tool: manage_task

Your **PowerShell 7 (`pwsh`) + PSReadLine** environment is now fully configured and optimized for native Windows tooling.

---

### What Was Configured

1. **PowerShell 7 & PSReadLine 2.4.5 Profile** ([`Microsoft.PowerShell_profile.ps1`](file:///C:/Users/void/Documents/PowerShell/Microsoft.PowerShell_profile.ps1))
   - **Predictive IntelliSense (`HistoryAndPlugin`)**: Auto-suggests commands from your past execution history and active subsystem predictors.
   - **Interactive Menu Completion**: `Tab` and <kbd>Ctrl</kbd>+<kbd>Space</kbd> open a full interactive grid menu navigable with arrow keys.
   - **Prefix History Search**: Type any prefix (e.g. `git ` or `ssh `) and press <kbd>↑</kbd> / <kbd>↓</kbd> to cycle through matching commands only.
   - **Dynamic Prediction Views**: Default is sleek inline ghost text. Press <kbd>F2</kbd> anytime to toggle between **Inline** view and **List dropdown** view.
   - **Word & Line Suggestion Acceptance**: <kbd>Ctrl</kbd>+<kbd>f</kbd> accepts full suggestion; <kbd>Alt</kbd>+<kbd>f</kbd> accepts just the next word.
   - **Syntax Highlighting & Muted Ghost Text**: Balanced colors for dark terminals with non-intrusive grey inline predictions.
   - **Silent Bell**: Disabled terminal beeps (`BellStyle = None`).

2. **Native Tooling & Companion Modules Installed**
   - **`CompletionPredictor`**: Official Microsoft predictor feeding autocompletion results directly into PSReadLine's prediction dropdown.
   - **`posh-git`**: Rich Git status indicators and tab completions for branches/remotes.
   - **`Terminal-Icons`**: Color-coded file and folder glyphs in directory listings (`ls` / `dir`).
   - **Native Argument Completers**: Pre-registered for `winget` (Windows Package Manager) and `dotnet`.

3. **Windows Terminal Default Profile** ([`settings.json`](file:///C:/Users/void/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json))
   - Updated Windows Terminal default profile to **PowerShell 7** (instead of legacy Windows PowerShell 5.1).
   - Configured font to **Cascadia Code** with ligature support.

4. **Preserved Custom Utilities**
   - Kept all your custom functions (`wakepc`, `sshpc`, `phonebattery`, `sshphone`, `fixstream`, `checkmonitors`).
   - Created a safety backup at [`Microsoft.PowerShell_profile.ps1.bak`](file:///C:/Users/void/Documents/PowerShell/Microsoft.PowerShell_profile.ps1.bak).

---

### Key Shortcuts Cheatsheet

| Shortcut | Action |
| :--- | :--- |
| <kbd>F2</kbd> | **Toggle Prediction View** between Inline ghost text & List dropdown menu |
| <kbd>Ctrl</kbd> + <kbd>f</kbd> | Accept entire predictive suggestion |
| <kbd>Alt</kbd> + <kbd>f</kbd> | Accept next word of prediction |
| <kbd>↑</kbd> / <kbd>↓</kbd> | History search filtered by whatever prefix you've typed |
| <kbd>Tab</kbd> / <kbd>Ctrl</kbd> + <kbd>Space</kbd> | Interactive arrow-navigable completion menu |
| <kbd>Shift</kbd> + <kbd>Enter</kbd> | Insert a new line without executing (multi-line commands) |
| <kbd>Ctrl</kbd> + <kbd>z</kbd> / <kbd>Ctrl</kbd> + <kbd>y</kbd> | Undo / Redo command-line edits |
| <kbd>Ctrl</kbd> + <kbd>Backspace</kbd> / <kbd>Delete</kbd> | Delete previous / next word |
| `reload-profile` | Hot-reload your profile in the current session |
| `admin` | Launch an elevated PowerShell 7 window |

---

### Optional: Nerd Font for Terminal Glyphs
To render full icon glyphs in `Terminal-Icons` and Oh My Posh, run:
```powershell
oh-my-posh font install Meslo
```
*(or CascadiaCode)*, and select it in Windows Terminal settings (**Settings → Defaults → Appearance → Font face**).