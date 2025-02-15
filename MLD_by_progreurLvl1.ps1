############
# Script provided for free by progreurlvl1 under GNU 3.0 Licence
# MLD, multiple link downloader, allows you to automatically download a large number of links contained in a text file

# For any inquiries, contact progreurlvl1 (GitHub)

# Prerequisites: requires a text file with download links, here "pdf.txt", which should be located in the same folder as this script
# Run the script: right-click, execute with Powershell (or cmd, terminal)
# Interrupt the script: ctrl + c
# Technical details: the script ignores empty lines or lines that do not contain a URL, and generates a log file (which can be disabled) where errors are logged to facilitate support
############

############
# Modifiable part (can also be modified dynamically when launching the script)
$URLFileDefault = "urls.txt"
$DLFolderDefault = "Downloads"
$activateLogs = $true # Set $false to disable logs
############

############
# Non-modifiable part
# Ask for the path of the file containing the URLs
$URLFile = Read-Host "Enter the path of the file containing the URLs (default: $URLFileDefault)"
if ([string]::IsNullOrWhiteSpace($URLFile)) {
    $URLFile = $URLFileDefault
}

# Ask for the download folder
$DLFolder = Read-Host "Enter the folder to save the files (default: $DLFolderDefault)"
if ([string]::IsNullOrWhiteSpace($DLFolder)) {
    $DLFolder = $DLFolderDefault
}

if (!(Test-Path -Path $DLFolder)) { New-Item -ItemType Directory -Path $DLFolder | Out-Null }
if (!(Test-Path -Path $URLFile)) {
    Write-Host "The file containing the URLs ($URLFile) could not be found."
    Read-Host "Press Enter to exit..."
    exit
}

$URLs = Get-Content -Path $URLFile
$Total = $URLs.Count
$Succes = 0
$Failures = 0
$SkippedLines = 0
$LogFile = "MLD_logs.txt"

# If logs are enabled, initialize the StreamWriter
if ($activateLogs) {
    # Add a header with the date and time of the launch
    $StartDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $StreamWriter = [System.IO.StreamWriter]::new($LogFile, $true)

    # Add a separator at the beginning of the logs for this launch
    $StreamWriter.WriteLine("`n---------------------------- Launch: $StartDate ----------------------------`n")
}

# Filter valid URLs (ignore empty lines or lines containing only spaces)
$validURLs = $URLs | Where-Object { ![string]::IsNullOrWhiteSpace($_) -and $_ -match "^(http|https)://" }
$TotalValids = $validURLs.Count

for ($Index = 0; $Index -lt $TotalValids; $Index++) {
    $URL = $validURLs[$Index].Trim()  # Use valid URLs
    Write-Progress -Activity "Downloading files..." -Status "Downloading $(($Index + 1)) of $TotalValids" -PercentComplete ((($Index + 1) / $TotalValids) * 100)

    try {
        if ($URL -match "^(http|https)://") {
            if ($URL -match "/([^/]+\.[a-zA-Z0-9]+)$") {
                $FileName = $Matches[1]
            } else {
                $FileName = (Get-Date -Format "yyyyMMdd_HHmmss") + ".dat"
            }

            $DestinationPath = Join-Path -Path $DLFolder -ChildPath $FileName
            $Counter = 1
            while (Test-Path -Path $DestinationPath) {
                $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
                $Extension = [System.IO.Path]::GetExtension($FileName)
                $FileName = "$BaseName($Counter)$Extension"
                $DestinationPath = Join-Path -Path $DLFolder -ChildPath $FileName
                $Counter++
            }

            Invoke-WebRequest -Uri $URL -OutFile $DestinationPath -ErrorAction Stop
            $Succes++
            if ($activateLogs) {
                $StreamWriter.WriteLine("URL success : $URL")
            }
        } else {
            # Ignore lines without valid URLs
            $SkippedLines++
        }
    } catch {
        $Failures++
        if ($activateLogs) {
            $StreamWriter.WriteLine("URL error : $URL - $($_.Exception.Message)")
        }
    }
}

# Add a separator at the end of the logs for this launch if logs are enabled
if ($activateLogs) {
    $StreamWriter.WriteLine("`n---------------------------- End of Launch: $StartDate ----------------------------`n")
    $StreamWriter.Close()
}

Write-Host "Downloads completed."
Write-Host "Success: $Succes"
Write-Host "Failures: $Failures"
Write-Host "Ignored lines (empty or without a valid URL): $SkippedLines"
Write-Host "Files are saved in: $DLFolder"

if ($activateLogs) {
    Write-Host "Details in the log file: $LogFile"
}
Write-Host "Press Enter to exit..."
Read-Host
############
