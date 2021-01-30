<#
.SYNOPSIS

Open-Source PowerShell module developed by @TheShiShiLion to allow online play of Backdoors And Breaches card game devised by Black Hills Information Security

.DESCRIPTION

The goal of this module is to create an Open-Source version of Backdoors & Breaches to allow remote working teams to play together.
This should be done with minimal external dependencies, effort or additional investment to getting a game setup on LAN or - if required - hosted on the web on an ad-hoc basis.
This is a minimum viable product to allow teams to play Backdoors and Breaches with near zero installation effort or investment in time.  Once installed the following are the
steps involved in playing the first and subsequent rounds of the game.

Step 1. If it doesn't already exist - create the directory where the Incident Master game file will be created or updated e.g., c:\temp\master

Step 2. If it doesn't already exist - create the shared directory where players may access the game file from.  This must be different from the Incident Master path e.g., s:\SomeShareDrive\temp\player

Step 3. At the PowerShell prompt type the following:

PS> $game =Invoke-BackdoorsAndBreaches -Players "[Enter name of players separated by a comma]" -IncidentMasterOutputPath "[Path from Step 1]" -PlayerOutputPath "[Path from Step 2]" [-Verbose]

Example:

PS> $game =Invoke-BackdoorsAndBreaches -Players "Alice,Bob,Carol,Dave,Eve" -IncidentMasterOutputPath "C:\temp\master" -PlayerOutputPath "C:\temp\player"

Step 4: The script will generate an invitation template which can be shared via email with the players being invited to play.  The player page has a blue background.

Step 5: The incident master will follow a different link (also displayed when the script module is run.  This Incident Master page has a red background.  Once

Step 6: The incident master should introduce the game objectives and talk the players through the planned gameplay.  The specific scenario the incident master invents (typically based upon the initial access card) should be introduced.  Give the players 5 minutes to familiarise themselves with the procedure cards they've been dealt.  When the players are comfortable the incident master should ask what procedure card they want to play -OR- a different procedure not represented by a card (which won't give a +3 modifier to the next dice roll)

Step 7(I): The incident master should confirm the procedure the players want to play by name.  The incident master can then click the related card in the incident master (red) dashboard then copy and paste the text that appears in the dialogue into the PowerShell window used to initiate the game.  The incident master will then be prompted with next steps as follows:

    > Turn (1) : Ask players to describe the procedure they want to use.  Press [RETURN] to proceed when done:

WARNING: Once the incident master presses [RETURN] the dice will be rolled.

    > Turn (1) : Rolled n including modifier - can players solve a card?  Press [RETURN] to proceed when done:

Step 7(II): If the players don't want to play one of their procedures they can opt to play/describe one of their own known procedures.  However, they will not receive the +3 modifier on the dice roll.  To do this the incident master can click the "Take Turn" text at the bottom of the Gameplay box on the incident master (red) dashboard.  Then copy and paste the text that appears in the dialogue into the PowerShell window used to initiate the game. This will initiate the turn taking for the players without using a procedure.

Step 8: The incident master then decides if

    (a) if the players roll is greater than 10 AND
    (b) if the description of how the procedure will be applied sufficiently describes the expectations for investigation AND
    (c) if the procedure as described would positively identify one of the target game cards - initial compromise, Persistence, Pivot and Escalate, C2 and Exfil

Step 10: Repeat steps 7 and 8 with the players until 10 turns have been take or the players solve the 4 incident cards.  The incident master may want to introduce their own story narrative as the game progresses.

## Hosting/uploading the files online via FTPS (demo implementation)

This is completely optional and only relevant where players are from outside your organisation/network.  Most relevant where a network shared folder might not be available for access the "player game file".

The Incident Master and Player files still need to be generated locally before upload so follow Step 1 and Step 2 from the instructions above.

NOTE: Playing the game will automatically create and upload the "player" and "incidentmaster" files if they don't already exist.

.INPUTS

None. You cannot pipe objects to Add-Extension.

.OUTPUTS

Custom BackdoorsAndBreaches Game object against which game based activities can be called.  The precise syntax of method calls can be copied and pasted from the Incident Master dashboard by clicking on the target activity.

.EXAMPLE

Vanilla Game on local network - no FTPS upload.  Ideal for playing on corporate network with PlayerOutputPath to share drive accessible by all players.

PS> $game =Invoke-BackdoorsAndBreaches -Players "Alice,Bob,Carol,Dave,Evee" -IncidentMasterOutputPath "C:\temp\master\" -PlayerOutputPath "C:\temp\player\" -Verbose

.EXAMPLE

Game hosted on a remote server e.g. FTPS.  Obviously may not work on corporate networks where firewall rules don't allow chosen file tfer protocol acccess outbound. Easier to play from off corporate network if connectivity issues are encountered.

PS> $game =Invoke-BackdoorsAndBreaches -Players "Alice,Bob,Carol,Dave,Eve" -IncidentMasterOutputPath "C:\temp\master\" -PlayerOutputPath "C:\temp\player\" -FileXferConfig "C:\temp\ftps.config"


.LINK

https://github.com/TheShiShiLion/BackdoorsAndBreaches

.LINK

https://www.blackhillsinfosec.com/projects/backdoorsandbreaches/

#>


$global:nl = "`n"
$global:tab= "`t"
$Global:MaxProcedures=5

function Invoke-BackdoorsAndBreaches
{
        <#
        .SYNOPSIS
            Short description
        .DESCRIPTION
            Long description
        .EXAMPLE
            PS C:\> <example usage>
            Explanation of what the example does
        .INPUTS
            Inputs (if any)
        .OUTPUTS
            Output (if any)
        .NOTES
            General notes
        .AUTHOR
            Terry Wymer
        #>
    [CmdletBinding(DefaultParameterSetName='Default',
                SupportsShouldProcess=$false,
                PositionalBinding=$false,
                HelpUri = 'http://www.microsoft.com/',
                ConfirmImpact='Low')]
    Param
    (
        [Parameter( Position=1, Mandatory=$true, ValueFromPipelineByPropertyName=$false, HelpMessage="A comma separated list of player names. A minimum of 1 and maximum of 10 players can play.  Players are independent of the Incident Master" )]
        [String]$Players,

        [Parameter( Position=2, Mandatory=$true, ValueFromPipelineByPropertyName=$false, HelpMessage="The local path to the output directory for the Incident Master game file.  This will be the file Incident Master will access to play the game.  The default is the module output directory.  This should be a different output directory to the player output file." )]
        [ValidateScript({Test-Path $_} )]
        [String]$IncidentMasterOutputPath,

        [Parameter( Position=3, Mandatory=$true, ValueFromPipelineByPropertyName=$false, HelpMessage="Enter the local path to the output directory for the player game file.  This will be the file players will access to play the game.  The default is the module output directory.  This should be changed to ensure the player file is in a different directory to the Incident Master file.  In an office setting this would be path to a share all players can access." )]
        [ValidateScript({Test-Path $_} )]
        [String]$PlayerOutputPath,

        [Parameter( Position=4, Mandatory=$false, ValueFromPipelineByPropertyName=$false, HelpMessage="An optional parameter for playing from a shared hosting environment by transferring files using FTPS.  Requires local install of WinSCP.  Enter the local path to the FTPS Configuration file.  A sample FTPS configuration file can be found in the module directory." )]
        [ValidateScript({ if($null -ne $_) {Test-Path $_} else { $true }})]
        [String]$FileXferConfig,

        [Parameter( Position=5, Mandatory=$false, ValueFromPipelineByPropertyName=$false, HelpMessage="An optional parameter to specify the location of the default tabletop template" )]
        [ValidateScript({Test-Path $_} )]
        [String]$PlayerTemplatePath=$PSScriptRoot+"\..\templates\template.players.html",

        [Parameter( Position=6, Mandatory=$false, ValueFromPipelineByPropertyName=$false, HelpMessage="An optional parameter to specify the images directory.  Defult is a sub directory of the module install directory." )]
        [ValidateScript({Test-Path $_} )]
        [String]$CardImageDirectoryPath=$PSScriptRoot+"\..\images\",

        [Parameter( Position=7, Mandatory=$false, ValueFromPipelineByPropertyName=$false, HelpMessage="An optional parameter to specify the CSS directory.  Defult is a sub directory of the module install directory." )]
        [ValidateScript({Test-Path $_} )]
        [String]$CSSDirectoryPath=$PSScriptRoot+"\..\css\"
    )
    try
    {
        if( $IncidentMasterOutputPath -eq $PlayerOutputPath )
        {
            throw "Error: The local Player and Incident Master paths are pointing to the same directory.  Change one or the other. A dishonest player may access the Incident Master game file and cheat :O"
        }

        Write-Host "[+] Starting ..."$game.
        $banner = Get-Content -Path $PSScriptRoot+"\..\templates\banner.template.txt"

        $game = [Game]::new()
        if( $FileXferConfig -ne "")
        {
            $game.EnableFileXfer( $FileXferConfig )
            $banner = $banner.Replace( "[PLAYER_URL]", $game.FileXfer.URLforPlayers )
            $banner = $banner.Replace( "[INCIDENT_MASTER_URL]", $game.FileXfer.URLforIncidentMaster )
        } else {
            $banner = $banner.Replace( "[PLAYER_URL]","" )
            $banner = $banner.Replace( "[INCIDENT_MASTER_URL]","")
        }

        Write-Host "[+] Initialising ..."
        $game.setPlayerTemplate( $PlayerTemplatePath )
        $game.setGameMasterTemplate( $PlayerTemplatePath )
        $game.setWWWMasterRoot( $IncidentMasterOutputPath )
        $game.setWWWPlayerRoot( $PlayerOutputPath)

        $banner = $banner.Replace( "[PLAYER_PATH]", $PlayerOutputPath+"index.html" )
        $banner = $banner.Replace( "[INCIDENT_MASTER_PATH]", $IncidentMasterOutputPath+"index.html")
        foreach( $line in $banner ) { Write-Host $line -ForegroundColor Cyan  }

        Write-Verbose "[+] Adding Cards ..."
        Get-ChildItem -File $CardImageDirectoryPath | ForEach-Object {
            Write-Verbose "[+] Card $($_.Name)"
            $game.AddCardImage($_.Name)
        }

        $PlayerNames=$Players -split ','
        Write-Host "[+] Adding Players ..."
        foreach( $player in $PlayerNames){
            Write-Verbose "[+] Player $($player)"
            $game.AddPlayer( $player )
        }
        $game.Play()
        Write-Host "[+] Ready to Play"
        return $game
    }
    catch
    {
        Write-Error -Message $_
        throw '[-] Error thrown in Invoke-BackdoorsAndBreaches'
    }
}
