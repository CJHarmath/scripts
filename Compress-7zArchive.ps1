function Compress-7zArchive {
    <#
    .SYNOPSIS
        A 7zip based replacement for Compress-Archive
    .DESCRIPTION
        Compress-Archive is limited to files smaller than 2Gb and it's generally slower
        than 7zip, so this is an alternative wrapping 7z.exe to overcome those limitations
    
    .PARAMETER Path
    The path of the file or directory to be compressed
    
    .PARAMETER Destination
    The path of the destinaiton archive file. Default is the current working folder

    .PARAMETER CompressionLevel
    The compression level. Valid values are 0 (store) to 9 (ultra).
    The default value is 5 (normal).

    .PARAMETER Type
    The type of the archive. Can be either 7z or zip.
    By default it's zip for maximum compatibility.

    .PARAMETER ExecutablePath
    The path to the 7zip executable. If not specified, the function will
    search for 7zip in the PATH and in known installation locations.
    
    .PARAMETER InstallViaChocolatey
    A switch to indicate whether to install 7zip via chocolatey.org if it
    is not found.

    .LINK
        https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.archive/compress-archive?view=powershell-7.3#description
        https://www.7-zip.org/
    .EXAMPLE
        Test-MyTestFunction -Verbose
        Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
    #>
    
    
    [CmdletBinding()]
    param (
      [Parameter(Mandatory=$true)]
      [string] $Path,
  
      [Parameter()]
      [string] $Destination,
  
      [Parameter()]
      [ValidateRange(0, 9)]
      [int] $CompressionLevel = 5,

      [Parameter()]
      [ValidateSet("zip", "7z")]
      $Type = "zip",
  
      [Parameter()]
      [string] $ExecutablePath,
  
      [Parameter()]
      [switch] $InstallViaChocolatey
    )
  
    # Check if the 7zip executable path was specified
    if ($ExecutablePath -and (Test-Path $ExecutablePath)) {
      # Use the specified executable path
      $7zExecutable = $ExecutablePath
    }
    else {
      # Search for 7zip in the PATH
      $7zExecutable = (Get-Command 7z.exe).Path
  
      # Check if 7zip was not found in the PATH
      if (-not $7zExecutable) {
        # Check known installation locations for 7zip
        $knownLocations = @(
          "C:\ProgramData\chocolatey\bin\7z.exe"
          "C:\Program Files\7-Zip\7z.exe",
          "C:\Program Files (x86)\7-Zip\7z.exe"
        )
        foreach ($location in $knownLocations) {
          if (Test-Path $location) {
            $7zExecutable = $location
            break
          }
        }
      }
  
      # Check if 7zip was still not found
      if (-not $7zExecutable) {
        # Check if the InstallViaChocolatey switch was specified
        $hasChoco = (Get-Command choco.exe)
        if ($hasChoco -and $InstallViaChocolatey) {
          # Install 7zip via chocolatey.org
          choco install 7zip -y
          &refreshenv
          # Search for 7zip again in the PATH
          $7zExecutable = (Get-Command 7z.exe).Path
        }
        else {
          # Throw an error if 7zip was not found and the InstallViaChocolatey
          # switch was not specified
          throw "7zip executable not found. Specify the path to the executable using the -ExecutablePath parameter, or if using Chocolatey use the -InstallViaChocolatey switch to install 7zip via chocolatey.org."
        }
      }
    }
  
    # Build the destionation path if not specified
    if ($null -eq $Destination){
        $Destination = "{0}\{1}.{2}" -f (Get-Location),(Get-Item $Path).Name, $type

    }
        
    $7zCommand = "a -t$Type -mx=$CompressionLevel `"$Destination`" `"$Path`""
  
    try {
        & $7zExecutable $7zCommand
    } catch {
        Write-Error "Something failed while executing 7z"
        Write-Error -ErrorRecord $_
    }
  }
  