# A class to encapsulate Player processing of a BackdoorsAndBreaches PowerShell Module

class Player {
    [string]$Name
    [string]$Role
    [bool]$Turn

    Player(){
        $this.Name = 'Undefined Name'
        $this.Role = 'Undefined Role'
        $this.Turn = $false
    }

    Player( [string]$name )
    {
        $this.Name = $name
        $this.Role = 'Undefined Role'
        $this.Turn = $false
    }

    [void] Toggle()
    {
        if( $this.Turn -eq $false )
        {
            $this.Turn = $true
        } else {
            $this.Turn = $false
        }
    }
<#
    [void] Role( $r )
    {
        $this.Role=$r
        #$this.CurrentState = If ($this.CurrentState -ne $true) { $true } Else { $false }
    }
#>
    [string] Status()
    {
        return ""
    }

    [string] Display()
    {
        $buf=""
        if( $this.Turn -eq $true )
        {
            $buf='<p class="playerselected">'+$this.Name+' ('+$this.Role+')</p>'
        } else {
            $buf='<p class="player">'+$this.Name+' ('+$this.Role+')</p>'
        }
        return $buf
    }
}
