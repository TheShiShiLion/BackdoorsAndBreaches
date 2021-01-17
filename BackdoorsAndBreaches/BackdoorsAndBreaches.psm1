Using module '.\classes\Card.psm1'
Using module '.\classes\Player.psm1'
Using module '.\classes\Game.psm1'
Using module '.\classes\ConfigFile.psm1'
Using module '.\classes\FileXfer.psm1'

$functionFolders = @('public', 'private', 'classes')
ForEach ($folder in $functionFolders)
{
    $folderPath = Join-Path -Path $PSScriptRoot -ChildPath $folder
    If (Test-Path -Path $folderPath)
    {
        Write-Verbose -Message "Importing from $folder"
        $functions = Get-ChildItem -Path $folderPath -Filter '*.ps1'
        ForEach ($function in $functions)
        {
            Write-Verbose -Message "  Importing $($function.BaseName)"
            . $($function.FullName)
        }
    }
}
$publicFunctions = (Get-ChildItem -Path "$PSScriptRoot\public" -Filter '*.ps1').BaseName
Export-ModuleMember -Function $publicFunctions