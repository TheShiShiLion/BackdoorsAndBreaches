# This script is for testing purposes and to familiarise yourself with the Backdoors and Breaches gameplay.
# It's suggested to set a breakpoint  on the line with the Invoke-BackdoorsAndBreaches call.
#
Clear-Host
Set-Location $PSScriptRoot

# Remove residue from any previous install
Remove-Module -Name BackdroorsAndBreaches -Force -ErrorAction SilentlyContinue
Uninstall-Module -Name BackdoorsAndBreaches -Force -ErrorAction SilentlyContinue

# Code included for testing purposes
Test-ModuleManifest .\BackdoorsAndBreaches\BackdoorsAndBreaches.psd1

# Install the module
Unblock-File .\BackdoorsAndBreaches\BackdoorsAndBreaches.psd1
Import-Module .\BackdoorsAndBreaches\BackdoorsAndBreaches.psd1 -Force
Get-Module -Name BackdoorsAndBreaches

# Create Incident Master output directory on local system for testing
$MasterPath = "C:\temp\master\"
If(!(test-path $MasterPath)) { New-Item -ItemType Directory -Force -Path $MasterPath }

# Create Players directory - this can/should also be a mapped network share where the players on the local network will also have access
$PlayerPath = "C:\temp\player\"
If(!(test-path $PlayerPath)) { New-Item -ItemType Directory -Force -Path $PlayerPath }

# Vanilla Game on local system/network - no FTPS upload.  Ideal for playing on corporate network with PlayerOutputPath to share drive accessible by all players
#$game =Invoke-BackdoorsAndBreaches -Players "Alice,Bob,Carol,Dave,Eve" -IncidentMasterOutputPath $MasterPath -PlayerOutputPath $PlayerPath

# The successful run of the previous command should output an invite template which can be cut-and-pasted into and email before sending to the players separately.
# Links to both the player and incident master dashboards will be displayed in the initial invoke output.  Just open in a browser.
# Then step through the below in debug mode to see how gameplay proceeds on both the player and incident master dashboards.

# Game hosted on a remote server e.g. FTPS.  Obviously may not work on corporate networks where firewall rules don't allow chosen file tfer protocol acccess outbound.
# Easier to play from off corporate network if connectivity issues are encountered.
$game =Invoke-BackdoorsAndBreaches -Players "Alice,Bob,Carol,Dave,Eve" -IncidentMasterOutputPath $MasterPath -PlayerOutputPath $PlayerPath -FileXferConfig "C:\temp\fileXfer.config"

# IMPORTANT: navigate to the incidentmaster link in a browser and click on cards to see commands that can be run against the created $game object.
# The incidnet master can use their dashboard as a cheatsheet to ensure the right command is run based upon the cards displayed and requests from the players.

# Play first prodedure
$game.PlayProcedure(0)

# Play second prodedure
$game.PlayProcedure(1)

# Play third prodedure
$game.PlayProcedure(2)

# Play fourth prodedure
$game.PlayProcedure(3)

# Play a prodedure of the players choice/invention/experience (no card selected - no +3 modifier)
$game.TakeTurn($false)

# Players solve Initial Compromise - reveal card
$game.RevealInitialCompromise()

# Players solve Persistence - reveal card
$game.RevealPersistence()

# Players solve Pivot and Escalate - reveal card
$game.RevealPivotAndEscalate()

# Players solve C2 and Exfil - reveal card
$game.RevealC2AndExfil()

# Injects will be revealed automatically based upon a roll of a 1, 20 or three losing turns
# It's possible for a new procedure card to be introduced by inject card.  If so, flip the last procedure card using the following command.
$game.ToggleProcedure(4)
