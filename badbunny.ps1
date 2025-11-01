$ErrorActionPreference = "SilentlyContinue"
Clear-Host

@"
    ____            ____                           
   / __ )____ _____/ / /_  __  ______  ____  __  __
  / __  / __ `/ __  / __ \/ / / / __ \/ __ \/ / / /
 / /_/ / /_/ / /_/ / /_/ / /_/ / / / / / / / /_/ / 
/_____/\__,_/\__,_/_.___/\__,_/_/ /_/_/ /_/\__, /  
                                          /____/  
"@ | Write-Host -ForegroundColor Cyan

Write-Host "          Made with love by emirate <3`n" -ForegroundColor Magenta

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Warning "Please run this script as Administrator."
    Start-Sleep 5
    exit
}

function Get-Signature {
    param ([string]$FilePath)
    if (-not (Test-Path $FilePath -PathType Leaf)) { return "File Not Found / Deleted" }
    $sig = (Get-AuthenticodeSignature -FilePath $FilePath -ErrorAction SilentlyContinue).Status
    switch ($sig) {
        "Valid"        { return "Valid Signature" }
        "NotSigned"    { return "Not Signed" }
        "HashMismatch" { return "Hash Mismatch" }
        "NotTrusted"   { return "Not Trusted" }
        "UnknownError" { return "Unknown Signature Error" }
        default        { return "Invalid / Unknown Signature" }
    }
}

$sw = [Diagnostics.Stopwatch]::StartNew()

if (!(Get-PSDrive -Name HKLM -PSProvider Registry)) {
    try { New-PSDrive -Name HKLM -PSProvider Registry -Root HKEY_LOCAL_MACHINE } catch { Write-Warning "Error Mounting HKLM" }
}

function Get-AllBamUsers {
    param([string]$BasePath)
    $allSids = @()
    if (Test-Path $BasePath) {
        $subkeys = Get-ChildItem -Path $BasePath -Recurse -ErrorAction SilentlyContinue
        foreach ($subkey in $subkeys) {
            if ($subkey.PSChildName -match '^\S+$') {
                $allSids += $subkey.PSChildName
            }
        }
    }
    return $allSids | Select-Object -Unique
}

$bamRoots = @("HKLM:\SYSTEM\CurrentControlSet\Services\bam\", "HKLM:\SYSTEM\CurrentControlSet\Services\bam\state\")
$AllUsers = @()
foreach ($root in $bamRoots) {
    $AllUsers += Get-AllBamUsers -BasePath "$root\UserSettings\"
}
$AllUsers = $AllUsers | Select-Object -Unique

$UserInfo = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation"
$Bias = -([convert]::ToInt32([Convert]::ToString($UserInfo.ActiveTimeBias, 2), 2))
$Day = -([convert]::ToInt32([Convert]::ToString($UserInfo.DaylightBias, 2), 2))

$Bam = foreach ($Sid in $AllUsers) {
    foreach ($root in $bamRoots) {
        $userKeyPath = "$root\UserSettings\$Sid"
        if (Test-Path $userKeyPath) {
            $properties = Get-ItemProperty -Path $userKeyPath -ErrorAction SilentlyContinue | Select-Object -Property *
            foreach ($prop in $properties.PSObject.Properties) {
                $Key = $prop.Value
                if ($Key -is [byte[]] -and $Key.Length -eq 24) {
                    $Hex = [System.BitConverter]::ToString($Key[7..0]) -replace "-", ""
                    $UTC = [DateTime]::FromFileTimeUtc([Convert]::ToInt64($Hex, 16))
                    $LocalTime = (Get-Date $UTC).ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss")
                    $UTCtime = (Get-Date $UTC).ToString("yyyy-MM-dd HH:mm:ss")
                    $UserTime = (Get-Date $UTC).AddMinutes($Bias).ToString("yyyy-MM-dd HH:mm:ss")

                    $Item = $prop.Name
                    if (((split-path -path $Item | ConvertFrom-String -Delimiter "\\").P3) -match '\d{1}') {
                        $cp = $Item.Remove(1, 23)
                        $Path = Join-Path -Path "C:" -ChildPath $cp
                        $File = Split-Path -Leaf ($Item).TrimStart()
                        $Sig = Get-Signature -FilePath $Path
                    } else {
                        $Path = $File = $Sig = ""
                    }

                    if (($Sig -ne "Valid Signature") -and ($Sig -ne "") -and ($Sig -ne $null)) {
                        try { $UserName = (New-Object System.Security.Principal.SecurityIdentifier($Sid)).Translate([System.Security.Principal.NTAccount]).Value } catch { $UserName = "" }

                        [PSCustomObject]@{
                            'Examiner Time'             = $LocalTime
                            'Last Execution Time (UTC)' = $UTCtime
                            'Last Execution User Time'  = $UserTime
                            Application                 = $File
                            Path                        = $Path
                            Signature                   = $Sig
                            User                        = $UserName
                            SID                         = $Sid
                            Regpath                     = $root
                        }
                    }
                }
            }
        }
    }
}

$Bam | Out-GridView -PassThru -Title "BAM key entries ($($Bam.Count)) - User TimeZone: ($($UserInfo.TimeZoneKeyName)) - Bias: ($Bias) - Daylight: ($Day)"

$sw.Stop()
Write-Host ""
Write-Host "Elapsed Time: $([math]::Round($sw.Elapsed.TotalMinutes, 2)) Minutes" -ForegroundColor Green
