<#
.SYNOPSIS
A class to encapsulate processing of a configuration file that can optionally have sections and stores name=value pairs

.DESCRIPTION
A class to encapsulate processing of a configuration file that can optionally have sections and stores name=value pairs
The default will be to look for a "configuration.txt" file in the current working directory but an alternative file path can be provided
It supports subsections through recognition of strings between "[" and "]"
All blank lines are ignored
Lines starting with # are treated as comments and ignored
All values are returned as strings
Once initialised, the "get" method will return the specified setting or an error if it doesn't exist

.EXAMPLE
Given a Configuration file as follows ->>>

# ignore this line
testsetting1=some setting 1
testsetting2=some setting 2
testsetting3=some setting 3


# ignore this line also
[Templates]
Path1=\path1\test1
Path2=\path1\test2
Path3=\path1\test3

<<<-

# create a Configuration file processing object
$cfg=[ConfigFile]::new( ".\configuration.ini" )

# print the contents (excluding any comments or white spaces)
Write-Host $cfg.Print()

# This will work
Write-Host "[+] 1:Path1 "$cfg.get( "Templates","Path1" )
Write-Host "[+] 2: "$cfg.get( "testsetting2" )
Write-Host "[+] 3: "$cfg.get( "Templates", "testsetting4"  )
Write-Host "[+] DONE"

#>

# TODO - Introduce more error checking!
class ConfigFile
{
    [hashtable] $sections

    ConfigFile()
    {
    }

    ConfigFile([string] $PathToConfiguraitonFile )
    {
        try
        {
            $this.sections=@{}
            if( Test-Path $PathToConfiguraitonFile )
            {
                $section=""
                ForEach( $line in Get-Content -Path $PathToConfiguraitonFile )
                {
                    if( $line.startswith("#") -ne $true -and $line -ne "" )
                    {
                        if( $line.startswith("[")) {
                            $Regex = [Regex]::new("(?<=\[)(.*)(?=\])")
                            $Match = $Regex.Match($line)
                            if($Match.Success)
                            {
                                $section=$Match.Value
                            }
                        } else {
                            $tmp = ConvertFrom-StringData $( $line -replace '\\', '\\')
                            if( $this.sections.Contains( $section ) -eq $false )
                            {
                                $this.sections.Add( $section, $tmp)
                            } else {
                                $SectionValue = $this.sections[$section]
                                $SectionValue += $tmp
                                $this.sections[$section]=$SectionValue
                            }
                        }
                    }
                }
            } else {
                throw "[-] Error: Configuration File doesn't exist - " + $PathToConfiguraitonFile
            }
        }
        catch
        {
            Write-Error -Message $_
            throw '[-] Error thrown in ConfigFile Class Constructor'
        }
    }

    [String] Print()
    {
        $buf=""
        $this.sections.Keys | ForEach-Object{
                $buf+="section =" + $_ +"`n"
            foreach( $setting in $this.sections.Item($_).keys ){
                $buf+="`t"+$setting +" = " + $this.sections.Item($_).Item($setting)+"`n"
            }
        }
        return $buf
    }

    [String] get( [String]$setting )
    {
        return $this.get( "", $setting)
    }

    [String] get( [String]$Section, [String]$setting )
    {
        if( $Null -eq $this.sections.Item($Section) ) { throw "Error: The specified configuration file section doesn't exist ("+$Section+")" }
        if( $Null -eq $this.sections.Item($Section).Item($setting) ) { throw "Error: The specified configuration file section setting doesn't exist ("+$Section+")("+$setting+")" }
        return $this.sections.Item($Section).Item($setting)
    }
}

<#
# Test code
cls
cd $PSScriptRoot
$cfg=[ConfigFile]::new( ".\configuration.ini" )
Write-Host $cfg.Print()
Write-Host "[+] 1:Path1 "$cfg.get( "Templates","Path1" )
Write-Host "[+] 2: "$cfg.get( "testsetting2" )
Write-Host "[+] 3: "$cfg.get( "Templates", "testsetting4"  )
#Write-Host "[+] DONE"
#>