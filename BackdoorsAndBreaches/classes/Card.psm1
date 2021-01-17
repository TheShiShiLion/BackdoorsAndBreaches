# A class to encapsulate Card processing of a BackdoorsAndBreaches PowerShell Module

class Card {
    [string]$Back
    [string]$Face
    [string]$Alt
    [int]$UnavailableCount=0
    [bool]$CurrentState

    Card(){
        $this.Back = 'Undefined Back Image'
        $this.Face = 'Undefined Face Image'
        $this.Alt = 'Undefined Alt'
    }

    Card(
        [string]$b,
        [string]$f,
        [string]$a
    ){
        $this.Back = $b
        $this.Face = $f
        $this.Alt = $a
        $this.CurrentState = $false
    }

    [void] Toggle()
    {
        $this.CurrentState = If ($this.CurrentState -ne $true) { $true } Else { $false }
    }

    [void] PlayCard()
    {
        $this.CurrentState = If ($this.CurrentState -ne $true) { $true } Else { $false }
        $this.UnavailableCount=3
    }

    [void] TakeTurn()
    {
        if( $this.UnavailableCount -ne 0 )
        {
            $this.UnavailableCount--
            if( $this.UnavailableCount -eq 0 )
            {
                # Make the card available again
                $this.CurrentState = $true
            }
        }
     }

    [string] DisplayPlayerBack()
    {
        return '<img class="card" id="'+$this.Back+'" src="images/'+$this.Back+'">'
    }

    [string] DisplayPlayerFace()
    {
        return '<img class="card" id="'+$this.Face+'" src="images/'+$this.Face+'">'
    }

    [string] DisplayIncidentMasterBack()
    {
        return '<img class="card" id="'+$this.Back+'" src="images/'+$this.Back+'" alt="'+$this.Alt+'" onclick="copyToClipboard('''+$this.Alt+''')">'
    }

    [string] DisplayIncidentMasterFace()
    {
        return '<img class="card" id="'+$this.Face+'" src="images/'+$this.Face+'" alt="'+$this.Alt+'" onclick="copyToClipboard('''+$this.Alt+''')">'
    }

    [string] PlayerDisplay()
    {
        If ($this.CurrentState -eq $true ) {
            return $this.DisplayPlayerFace()
        } else {
            return $this.DisplayPlayerBack()
        }
    }

    [string] MasterDisplay()
    {
        return $this.DisplayIncidentMasterFace()
    }

    [string] Status()
    {
        $buf=""
        if( $this.Back.Contains("procedure") )
        {
            if( $this.UnavailableCount -ne 0 )
            {
                $buf='<h3 class="unavailable">Available in '+ $this.UnavailableCount.ToString() +' Turn(s)</h3>'
            } else {
                $buf='<h3 class="available">&nbsp;</h3>'
            }
        } else {
            $buf='<h3 class="available">&nbsp;</h3>'
        }
        return $buf
    }
}