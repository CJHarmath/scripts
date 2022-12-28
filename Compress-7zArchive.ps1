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
    
    .PARAMETER DeleteSourceFiles
    A switch for wheter to delete the source files after compression. i.e.: to move to archive.

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
      [Switch] $DeleteSourceFiles,
  
      [Parameter()]
      [string] $ExecutablePath,
  
      [Parameter()]
      [switch] $InstallViaChocolatey
    )
    
    if (-not (Test-Path $Path)){
        throw "$Path does not exists!"
    }

    # Check if the 7zip executable path was specified
    if ($null -eq $ExecutablePath -and -not (Test-Path $ExecutablePath)) {
      # Search for 7zip in the PATH
      Write-Verbose "Searching 7z path..."
      $ExecutablePath = (Get-Command 7z).Path
  
      # Check if 7zip was not found in the PATH
      if ($null -eq $ExecutablePath) {
        # Check known installation locations for 7zip
        $knownLocations = @(
          "C:\ProgramData\chocolatey\bin\7z.exe"
          "C:\Program Files\7-Zip\7z.exe",
          "C:\Program Files (x86)\7-Zip\7z.exe"
        )
        foreach ($location in $knownLocations) {
          if (Test-Path $location) {
            $ExecutablePath = $location
            Write-Verbose "Using path: $ExecutablePath"
            break
          }
        }
      }
  
      # Check if 7zip was still not found
      if ($null -eq $ExecutablePath) {
        # Check if the InstallViaChocolatey switch was specified
        $hasChoco = (Get-Command choco.exe)
        if ($hasChoco -and $InstallViaChocolatey) {
          # Install 7zip via chocolatey.org
          Write-Verbose "attempting to install 7zip via chocolatey"
          choco install 7zip -y
          &refreshenv
          # Search for 7zip again in the PATH
          $ExecutablePath = (Get-Command 7z).Path
        }
        else {
          # Throw an error if 7zip was not found and the InstallViaChocolatey
          # switch was not specified
          throw "7zip executable not found. Specify the path to the executable using the -ExecutablePath parameter, or if using Chocolatey use the -InstallViaChocolatey switch to install 7zip via chocolatey.org."
        }
      }
    }
  
    # Build the destination path if not specified
    if ($null -eq $Destination -or [System.IO.Directory]::Exists($Path)) {
        $Destination = "{0}\{1}.{2}" -f (Get-Location),(Get-Item $Path).Name, $type
    }

    # if destination is a folder, change it to a file
    if ([System.IO.Directory]::Exists($Destination)){
        $Destination = [System.IO.Path]::Join($Destination,(Get-Item $Path).Name, $type)
    }

    if ($DeleteSourceFiles) {
        $7zArguments = "a -t$Type -mx=$CompressionLevel -sdel `"$Destination`" `"$Path`""
    } else {
        $7zArguments = "a -t$Type -mx=$CompressionLevel `"$Destination`" `"$Path`""
    }
  
    try {
        Write-Verbose "$ExecutablePath $7zArguments"
        $argList = $7zArguments -split " "
        $proc = Start-Process -FilePath $ExecutablePath -ArgumentList $argList -WorkingDirectory $(Get-Location) -PassThru -Wait -NoNewWindow
        if ($proc.ExitCode -ge 1) {
            Write-Error "7z failed"
        }
    } catch {
        Write-Error "Something failed while executing 7z"
        Write-Error -ErrorRecord $_
    }
  }
  