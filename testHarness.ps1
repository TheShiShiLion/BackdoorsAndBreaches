Set-Location $PSScriptRoot
clear-host
Remove-Module -Name BackdroorsAndBreaches -Force -ErrorAction SilentlyContinue
Uninstall-Module -Name BackdoorsAndBreaches -Force -ErrorAction SilentlyContinue

Test-ModuleManifest .\BackdoorsAndBreaches\BackdoorsAndBreaches.psd1
Unblock-File .\BackdoorsAndBreaches\BackdoorsAndBreaches.psd1
Import-Module .\BackdoorsAndBreaches\BackdoorsAndBreaches.psd1 -Force
Get-Module -Name BackdoorsAndBreaches
Clear-Host

# Vanilla Game on local network - no FTPS upload.  Ideal for playing on corporate network with PlayerOutputPath to share drive accessible by all players
$game =Invoke-BackdoorsAndBreaches -Players "Alice,Bob,Carol,Dave,Evee" -IncidentMasterOutputPath "C:\temp\master\" -PlayerOutputPath "C:\temp\player\"

# Game hosted on a remote server e.g. FTPS.  Obviously may not work on corporate networks where firewall rules don't allow chosen file tfer protocol acccess outbound.
# Easier to play from off corporate network if connectivity issues are encountered.
#$game =Invoke-BackdoorsAndBreaches -Players "Alice,Bob,Carol,Dave,Eve" -IncidentMasterOutputPath "C:\temp\master\" -PlayerOutputPath "C:\temp\player\" -FileXferConfig "C:\temp\fileXfer.config"

# IMPORTANT: navigate to the incidentmaster link in a browser and click on cards to see commands that can be run against the created $game object.
# The incidnet master can use this as a cheatsheet to ensure the right command is run based upon the cards displayed.

# For testing purposes and to familiarise yourself with the gameplay you can step through the below in debug mode to see how gameplay proceeds on both
# the player and incident master dashboards.

# Play first prodedure
$game.PlayProcedure(0)

# Play second prodedure
$game.PlayProcedure(1)

# Play third prodedure
$game.PlayProcedure(2)

# Play fourth prodedure
$game.PlayProcedure(3)

# Play a prodedure of the players choice (no card selected - no +3 modifier)
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
