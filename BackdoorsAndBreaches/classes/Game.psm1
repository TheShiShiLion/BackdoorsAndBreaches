# A class to encapsulate Game processing of a BackdoorsAndBreaches PowerShell Module

Using module '.\Card.psm1'
Using module '.\Player.psm1'
Using module '.\ConfigFile.psm1'
Using module '.\FileXfer.psm1'

class Game {
    [int] $MaxTurns
    [System.Collections.ArrayList] $Players = @()
    [System.Collections.ArrayList] $Roles = @()
    [System.Collections.ArrayList] $PlayerTurns = @()
    [bool] $Started=$false
    [int] $currentTurn=0
    [bool] $IsFileXfer=$false
    [FileXfer] $FileXfer

    <#
    The first set of cards is called Initial Compromise. These cards are red and represent how an attacker would first gain access to your network.
    The second set of cards is called C2 and EXFIL. These cards are brown and represent how an attacker would maintain access to the system they compromised on a network.
    The third set of cards is called PERSISTENCE. These cards are purple, and represent how an attacker would maintain access to a compromised system.
    The fourth set of cards is called PIVOT and ESCALATE. These cards are yellow and cover how an attacker would move around a network and escalate their privileges.
    The fifth set of cards is called PROCEDURES. These cards are blue, and represent the various Incident Response (IR) procedures an organization can use to identify and neutralize an attack.
    #>
    [System.Collections.ArrayList] $cardImages= @()
    [System.Collections.ArrayList] $InitialCompromises = @()
    [System.Collections.ArrayList] $C2AndExfils = @()
    [System.Collections.ArrayList] $Persistences = @()
    [System.Collections.ArrayList] $PivotAndEscalates = @()
    [System.Collections.ArrayList] $Procedures = @()

    [System.Collections.ArrayList] $Injected = @()
    [System.Collections.ArrayList] $Injects = @()

    [Card] $GameInitialCompromise
    [Card] $GameC2AndExfil
    [Card] $GamePersistence
    [Card] $GamePivotAndEscalate
    [System.Collections.ArrayList] $GameInjects = @()
    [System.Collections.ArrayList] $GameProcedures = @()

    [String] $PlayerTemplate=""
    [String] $GameMasterTemplate=""
    [String] $WWWMasterRoot=""
    [String] $WWWPlayerRoot=""

    [String] $Error=""
    [String] $Gameplay=""
    [int] $FailureCount=0

    [String] $URLforPlayers
    [String] $URLforIncidentMaster

    Game(){
        $this.MaxTurns = 10
    }

    Game(
        [int]$t
    ){
        $this.MaxTurns = $t
    }

    [void] AddPlayer( [String] $PlayerName )
    {

        $this.Players.Add( [Player]::New( $PlayerName ) )
    }


    [void] AddCardImage( [String]$image )
    {
        $this.cardImages.Add( $image )
    }


    [void] Play()
    {
        $this.Started=$true
        $this.AssignRoles()
        $this.CreateDeck()
        $this.Deal()
        $this.gameplay +="[+] Ready to play<br />"
        $this.Display()
    }

    [void] EnableFileXfer( [String]$configFilePath )
    {
        try {
            $cfg=[ConfigFile]::new( $configFilePath )
            $this.URLforPlayers = $cfg.get( "URLforPlayers"  )
            $this.URLforIncidentMaster = $cfg.get( "URLforIncidentMaster"  )

            $this.FileXfer = [FileXfer]::new( $configFilePath )
            $this.IsFileXfer=$true
        }
        catch
        {
            Write-Error -Message $_
            throw '[-] Error thrown in Game.EnableFileXfer'
        }
    }

    [String] Status()
    {
        $buffer="#######################################################################################"+$global:nl
        if( $this.Started -ne $true ) {
            $buffer += "[-] Game not started"
        } elseif ( $this.TurnCount -eq $this.MaxTurns ) {
            $buffer += "[X] GAME OVER"
        } else {
            # Game Status (Turn n of n)
            $buffer += "[+] Game Started (current turn "+$this.currentTurn+" of "+$this.MaxTurns+")"+$global:nl+$global:nl

            # Players and Roles
            $buffer+= "[+] Players"+$global:nl
            $this.PlayerTurns.GetEnumerator() | ForEach-Object{ $buffer+= $global:tab+$_.Display()+$global:nl  }

            # Procedures and Status
            $buffer+= $global:nl +"[+] Procedures and Status" +$global:nl
            foreach( $procedure in $this.GameProcedures )
            {
                $buffer+= $global:tab+$procedure.Status() +$global:nl
            }

            # Incident Cards and Status
            $buffer+= $global:nl +"[+] Incident Cards and Status" +$global:nl
            $buffer+= $global:tab+$this.GameInitialCompromise.Status() +$global:nl
            $buffer+= $global:tab+$this.GamePersistence.Status() +$global:nl
            $buffer+= $global:tab+$this.GamePivotAndEscalate.Status() +$global:nl
            $buffer+= $global:tab+$this.GameC2AndExfil.Status() +$global:nl
        }
        return $buffer
    }

    [void] AssignRoles()
    {
        $this.PlayerTurns=@()
        $this.Roles = @(
            "CISO"
            "Helpdesk"
            "IT Operations"
            "SOC Analyst (Network)"
            "SOC Analyst (Host)"
            "Security Engineer"
            "Head of Compliance"
            "Head of IT"
            "COO"
            "CEO"
        )
        [System.Collections.ArrayList] $playerSelected = @()
        [System.Collections.ArrayList] $roleSelected = @()
        $count=0
        $allAssigned=$false
        while( $allAssigned -eq $false )
        {
            $playerOffset=($this.SelectRamdomOffset( $this.Players.Count  )) -1
            if( $playerSelected.Contains( $playerOffset ) -eq $false )
            {
                # Assign role to player
                $noRole=$true
                $role=""
                while( $noRole -eq $true )
                {
                    $roleOffset=($this.SelectRamdomOffset( $this.Players.Count  ))-1
                    if( $roleSelected.Contains( $roleOffset ) -eq $false )
                    {
                        $role=$this.Roles[ $roleOffset ]
                        $roleSelected.Add( $roleOffset )
                        $noRole = $false
                    }
                }
                $this.Players[ $playerOffset ].Role=$role
                $this.Players[ $playerOffset ].Turn=$false
                $this.PlayerTurns.Add( $this.Players[ $playerOffset ] )
                $playerSelected.add( $playerOffset )
                $count += 1
                if( $count -eq  $this.Players.Count )
                {
                    $allAssigned=$true
                }
            }
        }
        #  Set $this.PlayerTurns at offset 0 to True to denote it's the first players turn
        $this.PlayerTurns[0].Toggle()
    }

    [void] SetPlayerTemplate( [String] $f )
    {
        if( ( Test-Path $f -PathType Leaf ) -eq $false )
        {
            $this.Error += "[-] Error: Player Template file doesn't exist"
        } else {
            $this.PlayerTemplate=$f
        }
    }

    [void] SetGameMasterTemplate( [String] $f )
    {
        if(( Test-Path $f -PathType Leaf ) -eq $false )
        {
            $this.Error += "[-] Error: Game Master Template file doesn't exist"
        } else {
            $this.GameMasterTemplate=$f
        }
    }

    [void] setWWWMasterRoot( [String] $d )
    {
        if(( Test-Path $d -PathType Container ) -eq $false )
        {
            $this.Error += "[-] Error: WWWMasterRoot path doesn't exist"
        } else {
            $this.WWWMasterRoot=$d

            # Verify support files such as images and CSS are copied from the module install directory so the generated page displays correctly in it's new location
            $ImagesSourceFolder = (get-item $PSScriptRoot ).parent.FullName+"\images\"
            $ImagesTargetFolder = $this.WWWMasterRoot+"images"
            $ImagesFTPSTargetFolder  = $this.FileXfer.IncidentMasterUploadURI+"images/"

            $CSSSourceFolder = (get-item $PSScriptRoot ).parent.FullName+"\css\"
            $CSSTargetFolder =  $this.WWWMasterRoot+"css"
            $CSSFTPSTargetFolder  = $this.FileXfer.IncidentMasterUploadURI+"css/"

            if( (Test-Path -Path $ImagesTargetFolder -PathType Container) -eq $false )
            {
                New-Item -ItemType "directory" -Path $ImagesTargetFolder
                Get-ChildItem -Path $ImagesSourceFolder | Copy-Item -Destination $ImagesTargetFolder -Recurse
            }

            if( (Test-Path -Path $CSSTargetFolder -PathType Container) -eq $false )
            {
                New-Item -ItemType "directory" -Path $CSSTargetFolder
                Get-ChildItem -Path $CSSSourceFolder | Copy-Item -Destination $CSSTargetFolder -Recurse
            }

            # Verify the support files exist on the target FileXfer Server (e.g. FTPS).  IF not - upload them there also.
            if( $true -eq $this.IsFileXfer )
            {
                # Upload of files can be time consuming.  Only upload if the target directories don't exist
                if( $this.FileXfer.FileExists( $ImagesFTPSTargetFolder ) -ne $true )
                {
                    $this.FileXfer.UploadDirectory( $ImagesSourceFolder, $ImagesFTPSTargetFolder )
                }
                if( $this.FileXfer.FileExists( $CSSFTPSTargetFolder ) -ne $true )
                {
                    $this.FileXfer.UploadDirectory( $CSSSourceFolder, $CSSFTPSTargetFolder )
                }
            }
        }
    }

    [void] setWWWPlayerRoot( [String] $d )
    {
        if(( Test-Path $d -PathType Container ) -eq $false )
        {
            $this.Error += "[-] Error: WWWPlayerRoot path doesn't exist"
        } else {
            $this.WWWPlayerRoot=$d

            $ImagesSourceFolder = (get-item $PSScriptRoot ).parent.FullName+"\images\"
            $ImagesTargetFolder = $this.WWWPlayerRoot+"images"
            $ImagesFTPSTargetFolder  = $this.FileXfer.PlayerUploadURI+"images/"

            $CSSSourceFolder = (get-item $PSScriptRoot ).parent.FullName+"\css\"
            $CSSTargetFolder =  $this.WWWPlayerRoot+"css"
            $CSSFTPSTargetFolder  = $this.FileXfer.PlayerUploadURI+"css/"

            # Verify support files such as images are copied from the module install directory so the generated page displays correctly in it's new location
            $ImagesTargetFolder =  $this.WWWPlayerRoot+"images"
            if( (Test-Path -Path $ImagesTargetFolder -PathType Container) -eq $false )
            {
                New-Item -ItemType "directory" -Path $ImagesTargetFolder
                $ImagesSourceFolder = (get-item $PSScriptRoot ).parent.FullName+"\images\"
                Get-ChildItem -Path $ImagesSourceFolder | Copy-Item -Destination $ImagesTargetFolder -Recurse
            }

            $CSSTargetFolder =  $this.WWWPlayerRoot+"css"
            if( (Test-Path -Path $CSSTargetFolder -PathType Container) -eq $false )
            {
                New-Item -ItemType "directory" -Path $CSSTargetFolder
                $CSSSourceFolder = (get-item $PSScriptRoot ).parent.FullName+"\css\"
                Get-ChildItem -Path $CSSSourceFolder | Copy-Item -Destination $CSSTargetFolder -Recurse
            }

            # Verify the support files exist on the target FileXfer Server (e.g. FTPS).  IF not - upload them there also.
            if( $true -eq $this.IsFileXfer )
            {
                # Upload of files can be time consuming.  Only upload if the target directories don't exist
                if( $this.FileXfer.FileExists( $ImagesFTPSTargetFolder ) -ne $true )
                {
                    $this.FileXfer.UploadDirectory( $ImagesSourceFolder, $ImagesFTPSTargetFolder )
                }
                if( $this.FileXfer.FileExists( $CSSFTPSTargetFolder ) -ne $true )
                {
                    $this.FileXfer.UploadDirectory( $CSSSourceFolder, $CSSFTPSTargetFolder )
                }
            }
        }
    }

    [void] CreateDeck()
    {
        # Iterate through card images and create sub decks based upon file naming convention to allow for easy future expansion
        foreach ($image in $this.cardImages) {
            switch ( $image ){
                {$_.contains("back")} { Break}
                {$_.contains("initialcompromise")} { $this.InitialCompromises.Add( [Card]::new( "master.back.initialcompromise.png", $image, "`$game.RevealInitialCompromise()") ); Break}
                {$_.contains("c2andexfil")} { $this.C2AndExfils.Add( [Card]::new( "master.back.c2andexfil.png", $image, "`$game.RevealC2AndExfil()") ); Break}
                {$_.contains("persistence")} { $this.Persistences.Add( [Card]::new( "master.back.persistence.png", $image, "`$game.RevealPersistence()") ); Break}
                {$_.contains("pivotandescalate")} { $this.PivotAndEscalates.Add( [Card]::new( "master.back.pivotandescalate.png", $image, "`$game.RevealPivotAndEscalate()") ); Break}
                {$_.contains("inject")} { $this.Injects.Add( [Card]::new( "master.back.inject.png", $image, "Inject") ); Break}
                {$_.contains("procedure")} { $this.Procedures.Add( [Card]::new( "master.back.procedure.png", $image, "Procedure") ); Break}
                Default {
                    "No matches"
                }
            }
        }
        $this.gameplay +="[+] Deck Created<br />"
    }

    [void] Deal()
    {
        # Deal the cards to play with against the various decks
        $this.GameInitialCompromise = $this.InitialCompromises[ ($this.SelectRamdomOffset( $this.InitialCompromises.Count )) -1 ]
        $this.GameC2AndExfil = $this.C2AndExfils[ ($this.SelectRamdomOffset( $this.C2AndExfils.Count )) -1 ]
        $this.GamePersistence = $this.Persistences[ ($this.SelectRamdomOffset( $this.Persistences.Count )) -1 ]
        $this.GamePivotAndEscalate = $this.PivotAndEscalates[ ($this.SelectRamdomOffset( $this.PivotAndEscalates.Count )) -1 ]

        [System.Collections.ArrayList] $selected = @()
        $allSelected=$false
        $count=0
        while( $allSelected -eq $false )
        {
            $offset=($this.SelectRamdomOffset( $this.Procedures.Count )) -1
            if( $selected.Contains( $offset ) -eq $false )
            {
                $this.GameProcedures.Add( $this.Procedures[ $offset ] )
                $this.GameProcedures[ $this.GameProcedures.Count -1 ].Toggle()
                $this.GameProcedures[ $this.GameProcedures.Count -1 ].Alt = "`$game.PlayProcedure( "+($this.GameProcedures.Count -1).toString() +")"
                $selected.Add( $offset )
                $count +=1
                if( $count -eq $Global:MaxProcedures )
                {
                    $allSelected = $true
                }
            }
        }
        # The last procedure isn't available by default on dealing.  It may become available through an inject
        $this.GameProcedures[ $this.GameProcedures.Count -1 ].Toggle()
        $this.GameProcedures[ $this.GameProcedures.Count -1 ].Alt = "`$game.ToggleProcedure( "+($this.GameProcedures.Count -1).toString() +")"

        # Randomise the Inject Cards for the purposes of the game
        $selected = @()
        $allSelected=$false
        $count=1
        while( $allSelected -eq $false )
        {
            $offset=($this.SelectRamdomOffset( $this.Injects.Count )) -1
            if( $selected.Contains( $offset ) -eq $false )
            {
                $this.GameInjects.Add( $this.Injects[ $offset ] )
                $selected.Add( $offset )
                $count +=1
                if( $count -eq $this.Injects.Count )
                {
                    $allSelected = $true
                }
            }
        }
        $this.gameplay +="[+] Cards dealt<br />"
    }

    [void] DealInject()
    {

        $this.Inject = $this.Injects[ ($this.SelectRamdomOffset( $this.Injects.Count )) -1 ]
        # TODO - Make sure we can't deal the same inject card twice

        $this.gameplay +="[+] Inject dealt<br />"
    }

    [void] ToggleProcedure( [int] $i )
    {
        $this.GameProcedures[ $i ].Toggle()
        $this.GameProcedures[ $i ].Alt = "`$game.PlayProcedure( "+$i.toString() +")"
        $this.Display()
    }

    [void] PlayProcedure( [int] $i )
    {
        $this.TakeTurn( $true )
        $this.Display()

        # Procedure played - now remove the procedure from the UI
        $this.GameProcedures[ $i ].PlayCard()
        $this.Display()
    }

    [void] RevealInitialCompromise()
    {
        $this.GameInitialCompromise.Toggle()
        $this.gameplay +="[+] Revealed Initial Compromise card<br />"
        $this.Display()
    }

    [void] RevealC2AndExfil()
    {
        $this.GameC2AndExfil.Toggle()
        $this.gameplay +="[+] Revealed C2 and Exfil card<br />"
        $this.Display()
    }

    [void] RevealPersistence()
    {
        $this.GamePersistence.Toggle()
        $this.gameplay +="[+] Revealed Persistence card<br />"
        $this.Display()
    }

    [void] RevealPivotAndEscalate()
    {
        $this.GamePivotAndEscalate.Toggle()
        $this.gameplay +="[+] Revealed Pivot and Escalate card<br />"
        $this.Display()
    }

    [int] SelectRamdomOffset( $max )
    {
        return 1..$max | Get-Random
    }

    [int] RollDice()
    {
        return 1..20 | Get-Random
    }


    [void] Display()
    {
        $playerbuffer = Get-Content $this.PlayerTemplate
        $masterbuffer = Get-Content $this.PlayerTemplate

        ##
        ## PLAYER
        ##
        for( $i=0; $i -lt $Global:MaxProcedures; $i++ )
        {
            $tag='[Procedure_'+($i+1).toString()+']'
            $playerbuffer = $playerbuffer.replace( $tag, $this.GameProcedures[$i].PlayerDisplay() )
            $playerbuffer = $playerbuffer.replace( '[Procedure_'+($i+1).toString()+'_status]', $this.GameProcedures[$i].Status() )
        }
		$playerbuffer = $playerbuffer.replace('[players_turns]', $this.PlayerStatus())
		$playerbuffer = $playerbuffer.replace('[Template_Role]', "incidentresponder")
        $playerbuffer = $playerbuffer.replace('[InitialCompromise]', $this.GameInitialCompromise.PlayerDisplay() )
        $playerbuffer = $playerbuffer.replace('[InitialCompromise_status]', $this.GameInitialCompromise.Status() )
		$playerbuffer = $playerbuffer.replace('[Persistence]',   $this.GamePersistence.PlayerDisplay() )
		$playerbuffer = $playerbuffer.replace('[Persistence_status]',   $this.GamePersistence.Status() )
        $playerbuffer = $playerbuffer.replace('[PivotAndEscalate]', $this.GamePivotAndEscalate.PlayerDisplay() )
        $playerbuffer = $playerbuffer.replace('[PivotAndEscalate_status]', $this.GamePivotAndEscalate.Status() )
		$playerbuffer = $playerbuffer.replace('[C2AndExfil]',   $this.GameC2AndExfil.PlayerDisplay() )
		$playerbuffer = $playerbuffer.replace('[C2AndExfil_status]',   $this.GameC2AndExfil.Status() )
		$playerbuffer = $playerbuffer.replace('[Inject_deck]',  $this.GameInjects[0].PlayerDisplay() )
        $playerbuffer = $playerbuffer.replace('[Inject_deck_status]',  $this.GameInjects[0].Status() )
		$playerbuffer = $playerbuffer.replace('[Size_Reference_Card_Front]',  $this.GameInjects[0].Face )
        $playerbuffer = $playerbuffer.replace('[Size_Reference_Card_Back]',  $this.GameInjects[0].Back )
		$playerbuffer = $playerbuffer.replace('[gameplay]', $this.gameplay )
        $outfile=$this.WWWPlayerRoot+"index.html"
        Set-Content -Path $outfile -Value $playerbuffer

        If( $this.IsFileXfer -eq $true ){
            $this.FileXfer.UploadFile( $outfile, $this.FileXfer.PlayerUploadURI+"index.html" )
        }

        ##
        ## MASTER
        ##
        for( $i=0; $i -lt $Global:MaxProcedures; $i++ )
        {
            $tag='[Procedure_'+($i+1).toString()+']'
            $masterbuffer = $masterbuffer.replace( $tag, $this.GameProcedures[$i].MasterDisplay() )
            $masterbuffer = $masterbuffer.replace( '[Procedure_'+($i+1).toString()+'_status]', $this.GameProcedures[$i].Status() )
        }
		$masterbuffer = $masterbuffer.replace('[players_turns]', $this.PlayerStatus())
		$masterbuffer = $masterbuffer.replace('[Template_Role]', "incidentmaster")
        $masterbuffer = $masterbuffer.replace('[InitialCompromise]', $this.GameInitialCompromise.MasterDisplay() )
        $masterbuffer = $masterbuffer.replace('[InitialCompromise_status]', $this.GameInitialCompromise.Status() )
		$masterbuffer = $masterbuffer.replace('[Persistence]',   $this.GamePersistence.MasterDisplay() )
		$masterbuffer = $masterbuffer.replace('[Persistence_status]',   $this.GamePersistence.Status() )
        $masterbuffer = $masterbuffer.replace('[PivotAndEscalate]', $this.GamePivotAndEscalate.MasterDisplay() )
        $masterbuffer = $masterbuffer.replace('[PivotAndEscalate_status]', $this.GamePivotAndEscalate.Status() )
		$masterbuffer = $masterbuffer.replace('[C2AndExfil]',   $this.GameC2AndExfil.MasterDisplay() )
		$masterbuffer = $masterbuffer.replace('[C2AndExfil_status]',   $this.GameC2AndExfil.Status() )
		$masterbuffer = $masterbuffer.replace('[Inject_deck]',  $this.GameInjects[0].MasterDisplay() )
        $masterbuffer = $masterbuffer.replace('[Inject_deck_status]',  $this.GameInjects[0].Status() )
        $masterbuffer = $masterbuffer.replace('[Size_Reference_Card_Front]',  $this.GameInjects[0].Face )
        $masterbuffer = $masterbuffer.replace('[Size_Reference_Card_Back]',  $this.GameInjects[0].Back )
		$masterbuffer = $masterbuffer.replace('[gameplay]', $this.gameplay )

        $outfile=$this.WWWMasterRoot+"index.html"
        Set-Content -Path $outfile -Value $masterbuffer

        If( $this.IsFileXfer -eq $true ){
            $this.FileXfer.UploadFile( $outfile, $this.FileXfer.IncidentMasterUploadURI+"index.html" )
        }
    }

    [String] PlayerStatus()
    {
        $buffer=""
        foreach($player in $this.PlayerTurns )
        {
            $buffer+=$player.Display()
        }
        return $buffer
    }

    [void] ShowAllFaces()
    {
        # TODO
    }

    [void] ShowAllBacks()
    {
        # TODO
    }

    [void] SelectProcedure( [int] $i )
    {
        # TODO
    }

    [void] TakeTurn( [bool]$play_procedure )
    {
        <#
        Turns (What does the IR team member want to do? Why? Using what data source?)
        - Increment turn count
        -- If TurnCount == Max -3 then "Three turns to go"
        -- If TurnCount == Max -2 then "Two turns to go"
        -- If TurnCount == Max -1 then "Last turns to go"
        -- If TurnCount == Max -1 then "Last turns to go"
        - List ::available:: Defender cards
        - Option to chose ::available:: Defender Card
        - Defender provides legit narrative on the card
        #>
        $this.currentTurn += 1
        $turn=$this.currentTurn.toString()
        # Pause - Not doing anything with the return value.  Ask the player who's turn it is which procedure they wan to use
        $null = Read-Host "Turn ($turn) : Ask players to describe the procedure they want to use.  Press [RETURN] to proceed when done";
        $roll=$this.RollDice()

        # Playing a procedure so add a +3 modifier to the roll
        if( $true -eq $play_procedure ) {
            $roll_modified = $roll +3
        } else {
            $roll_modified = $roll
        }

        if( $roll_modified -lt 11 )
        {
            # unsuccessful roll
            $this.FailureCount++
        }
        if( $roll -eq 20 -or $roll -eq 1 -or $this.FailureCount -eq 3 )
        {
            # Deal an inject Card
            $this.FailureCount=0
            if( $true -eq $play_procedure ) {
                $this.gameplay +=$("[+] Turn "+$turn+" of "+$this.MaxTurns.toString()+": Rolled "+$roll.toString() +"+3 : *Inject Card*<br />")
            }else {
                $this.gameplay +=$("[+] Turn "+$turn+" of "+$this.MaxTurns.toString()+": Rolled "+$roll.toString() +" : *Inject Card*<br />")
            }
            $this.GameInjects[0].Toggle()
            $this.Display()
            # Pause - Not doing anything with the return value.  Inject Card introduced - check dashboard.
            $null = Read-Host "Turn ($turn) : Inject Card introduced - check dashboard.  Provide instruction to players. Press [RETURN] to proceed when done";

            # Reset the inject counter
            $this.FailureCount=0
            $this.GameInjects.RemoveAt(0)
            $this.Display()
        } else {
            <#
            - Add +3 for Blue Defender Card
            -- if( dice > 10 ) Defender Success
            ---- FailureCount = 0
            -- if( dice < 11 ) Defender Failure
            ---- Increment FailureCount
            - GM decides the level of IR team succces or failure based upon interpretation of "legit" defender narrative
            #>
            if( $true -eq $play_procedure ) {
                $this.gameplay +=$("[+] Turn "+$turn+" of "+$this.MaxTurns.toString()+" : Rolled "+$roll.toString()+"+3="+$roll_modified.toString()+"<br />")
            } else {
                $this.gameplay +=$("[+] Turn "+$turn+" of "+$this.MaxTurns.toString()+" : Rolled "+$roll.toString()+"<br />")
            }
            $this.Display()
            # Pause - Not doing anything with the return value.  "Turn ($turn) :  What did they roll?  If good enough and +3 for procedure - solve a card? "
            $im_prompt="Turn ($turn) : Rolled "+$roll_modified.toString()+" including modifier - can players solve a card?  Press [RETURN] to proceed when done"
            $null = Read-Host $im_prompt;
        }
        $triggerNext=$null
        $this.PlayerTurns.GetEnumerator() | ForEach-Object{  if($_.Turn -eq $true) { $triggerNext=$true; $_.Turn=$false } else { if( $null -ne $triggerNext ){ $_.Turn=$true; $triggerNext=$null }}}
        if( $triggerNext -eq $true )
        {
            # the last turn was the last player on the list.  Therefore play goes back to the start.
            $this.PlayerTurns[0].Toggle()
        }

        for( $i=0; $i -lt $this.GameProcedures.Count; $i++ )
        {
            $this.GameProcedures[ $i ].TakeTurn()
        }
        $this.Display()
    }

    [void] Reset()      # Reset everything except the players
    {
        # TODO
    }
}