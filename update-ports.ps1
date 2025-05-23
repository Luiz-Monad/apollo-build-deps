#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Updates vcpkg port cmake refs based on git submodule commits with correct SHA512.

.DESCRIPTION
    This script reads git submodules, downloads the corresponding GitHub tar.gz archives,
    calculates their SHA512 hashes, and updates the vcpkg port portfile.cmake files.

.PARAMETER PortsDirectory
    Path to the vcpkg ports directory. Defaults to "ports"

.PARAMETER SubmodulesFile
    Path to the .gitmodules file. Defaults to ".gitmodules"

.PARAMETER DryRun
    If specified, shows what changes would be made without actually modifying files

.EXAMPLE
    .\update-ports.ps1

.EXAMPLE
    .\update-ports.ps1 -PortsDirectory "my-ports" -DryRun
#>

param(
    [string]$PortsDirectory = "ports",
    [string]$SubmodulesFile = ".gitmodules",
    [switch]$DryRun
)

function Get-VcpkgPath {
    try {
        $vcpkgPath = Get-Command vcpkg -ErrorAction Stop | Select-Object -ExpandProperty Source
        return $vcpkgPath
    }
    catch {
        throw "vcpkg not found. Please specify -VcpkgRoot or ensure vcpkg is in PATH"
    }
}

function Get-GitSubmodules {
    param([string]$GitmodulesPath)
    if (-not (Test-Path $GitmodulesPath)) {
        Write-Error "Gitmodules file not found: $GitmodulesPath"
        return @()
    }

    $content = Get-Content $GitmodulesPath -Raw
    $submodules = @()

    # Parse .gitmodules file
    $sections = $content -split '\[submodule\s+"([^"]+)"\]' | Where-Object { $_ -match '\S' }

    for ($i = 0; $i -lt $sections.Count; $i += 2) {
        if ($i + 1 -ge $sections.Count) { break }
        $name = $sections[$i].Trim()
        $config = $sections[$i + 1]

        # Extract name from section header
        if ($name -match '\[submodule\s+"([^"]+)"\]') {
            $name = $matches[1]
        }

        # Clean up name
        $name = (Split-Path $name -Leaf)
        $name = if ($name -match '([^/]+)_git$') { $matches[1].Trim() } else { $name }
        $name = $name.ToLower()

        # Extract path, url, and branch
        $path = if ($config -match 'path\s*=\s*(.+)') { $matches[1].Trim() } else { $null }
        $url = if ($config -match 'url\s*=\s*(.+)') { $matches[1].Trim() } else { $null }
        $branch = if ($config -match 'branch\s*=\s*(.+)') { $matches[1].Trim() } else { $null }

        if ($path -and $url) {
            $submodules += @{
                Name   = $name
                Path   = $path
                Url    = $url
                Branch = $branch
            }
        }
    }

    return $submodules
}

function Get-CurrentCommitHash {
    param([string]$SubmodulePath)
    if (-not (Test-Path $SubmodulePath)) {
        Write-Warning "  Submodule path not found: $SubmodulePath"
        return $null
    }
    try {
        Push-Location $SubmodulePath
        $commitHash = git rev-parse HEAD
        Pop-Location
        return $commitHash.Trim()
    }
    catch {
        Write-Warning "  Failed to get commit hash for $SubmodulePath`: $_"
        if (Get-Location | Select-Object -ExpandProperty Path) {
            Pop-Location -ErrorAction SilentlyContinue
        }
        return $null
    }
}

function Get-GitHubRepoInfo {
    param([string]$GitUrl)

    # Parse GitHub URL to extract org/repo
    if ($GitUrl -match 'github\.com[:/]([^/]+)/([^/]+?)(?:\.git)?/?$') {
        return @{
            Org  = $matches[1]
            Repo = $matches[2]
        }
    }

    Write-Warning "  Could not parse GitHub URL: $GitUrl"
    return $null
}

function New-TempPortFile {
    param(
        [string]$PortName,
        [string]$Org,
        [string]$Repo,
        [string]$CommitHash,
        [string]$Branch,
        [string]$TempPortDir
    )

    $portfileContent = @"
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO $Org/$Repo
    REF $CommitHash
    SHA512 0
)
"@

    $vcpkgJsonContent = @"
{
    "name": "$PortName",
    "version": "0.0.0",
    "description": "Temporary port for SHA512 extraction"
}
"@

    New-Item -ItemType Directory -Path $TempPortDir -Force | Out-Null
    Set-Content -Path (Join-Path $TempPortDir "portfile.cmake") -Value $portfileContent
    Set-Content -Path (Join-Path $TempPortDir "vcpkg.json") -Value $vcpkgJsonContent
}

function Get-SHA512FromVcpkgError {
    param([string[]]$ErrorOutput)

    # Look for the actual hash in the error output
    $output = $ErrorOutput -join "`n"
    if ($output -match "Actual hash:\s*([a-fA-F0-9]{128})") {
        return $matches[1].ToLower()
    }

    Write-Warning "  Could not extract SHA512 from vcpkg output. Output was:`n$ErrorOutput"
    return $null
}

function Get-SHA512FromVcpkg {
    param(
        [string]$PortName,
        [string]$Org,
        [string]$Repo,
        [string]$CommitHash,
        [string]$Branch
    )
    $tempFile = $([System.IO.Path]::GetRandomFileName())
    $tempProjectDir = Join-Path $env:TEMP "$CommitHash-$tempFile"
    try {
        # Create temporary vcpkg project
        Write-Host "  Creating temporary directory: $tempProjectDir" -ForegroundColor DarkGray

        New-Item -ItemType Directory -Path $tempProjectDir -Force | Out-Null
        $tempPortsDir = Join-Path $tempProjectDir "ports"
        New-Item -ItemType Directory -Path $tempPortsDir -Force | Out-Null
        $tempPortDir = Join-Path $tempPortsDir $PortName
        New-Item -ItemType Directory -Path $tempPortDir -Force | Out-Null

        # Initialize vcpkg project
        Write-Host "    Creating temporary vcpkg project..." -ForegroundColor DarkGray

        New-TempPortFile `
            -PortName $PortName `
            -Org $Org `
            -Repo $Repo `
            -CommitHash $CommitHash `
            -Branch $Branch `
            -TempPortDir $tempPortDir

        # Run vcpkg install
        Write-Host "  Running vcpkg to get SHA512..." -ForegroundColor Cyan

        $output = $null
        try {
            Push-Location $tempProjectDir
            $vcpkgPath = Get-VcpkgPath
            & $vcpkgPath new --application 2>&1 | Out-Null
            & $vcpkgPath add port $PortName 2>&1 | Out-Null
            $output = & $vcpkgPath install --overlay-ports=ports 2>&1
        }
        catch {
            Write-Warning "  Failed to run vcpkg install: $_"
            return $null
        }
        finally {
            Pop-Location
        }

        # Get SHA512 from vcpkg error
        return (Get-SHA512FromVcpkgError -ErrorOutput $output)
    }
    catch {
        Write-Warning "  Error processing $PortName`: $_"
        return $null
    }
    finally {
        # Cleanup
        if (Test-Path $tempProjectDir) {
            Write-Host "    Cleaning up temporary directory..." -ForegroundColor DarkGray
            Remove-Item $tempProjectDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Update-PortFile {
    param(
        [string]$PortFilePath,
        [string]$NewRef,
        [string]$NewSHA512,
        [string]$Branch,
        [switch]$DryRun
    )
    if (-not (Test-Path $PortFilePath)) {
        Write-Error "Port file not found: $PortFilePath"
        return $false
    }
    try {
        $content = Get-Content $PortFilePath -Raw
        $originalContent = $content

        # Update the ref line (commit hash)
        $content = $content -replace 'set\(ref\s+[^)]+\)', "set(ref $NewRef)"

        # Update the branch line if provided
        $content = $content -replace 'set\(branch\s+[^)]+\)', "set(branch $Branch)"

        # Update the SHA512 for the download
        if ($NewSHA512) {
            $content = $content -replace 'set\(sha512\s+[^)]+\)', "set(sha512 $NewSHA512)"
        }

        if ($content -ne $originalContent) {
            if ($DryRun) {
                Write-Host "Would update $PortFilePath" -ForegroundColor Yellow
                Write-Host "  Branch: $Branch" -ForegroundColor Cyan
                Write-Host "  New ref: $NewRef" -ForegroundColor Cyan
                if ($NewSHA512) {
                    Write-Host "  New SHA512: $NewSHA512" -ForegroundColor Cyan
                }
            }
            else {
                Set-Content $PortFilePath -Value $content -NoNewline
                Write-Host "Updated $PortFilePath" -ForegroundColor Green
                Write-Host "  Branch: $Branch" -ForegroundColor Cyan
                Write-Host "  New ref: $NewRef" -ForegroundColor Cyan
                if ($NewSHA512) {
                    Write-Host "  New SHA512: $NewSHA512" -ForegroundColor Cyan
                }
            }
            return $true
        }
        else {
            Write-Host "No changes needed for $PortFilePath" -ForegroundColor Green
            return $false
        }
    }
    catch {
        Write-Error "Failed to update $PortFilePath`: $_"
        return $false
    }
}

# Main script execution
Write-Host "Starting vcpkg port ref updates..." -ForegroundColor Blue

# Validate input paths
if (-not (Test-Path $PortsDirectory)) {
    Write-Error "Ports directory not found: $PortsDirectory"
    exit 1
}

if (-not (Test-Path $SubmodulesFile)) {
    Write-Error "Submodules file not found: $SubmodulesFile"
    exit 1
}

# Get all submodules
$submodules = Get-GitSubmodules -GitmodulesPath $SubmodulesFile
Write-Host "Found $($submodules.Count) submodules" -ForegroundColor Blue

$updatedCount = 0

foreach ($submodule in $submodules) {
    Write-Host "`nProcessing submodule: $($submodule.Name)" -ForegroundColor Magenta

    # Get port name
    $portName = $submodule.Name
    $portPath = $submodule.Path
    $portUrl = $submodule.Url
    $portDir = Join-Path $PortsDirectory $portName
    $portFile = Join-Path $portDir "portfile.cmake"

    Write-Host "  Port name: $portName"
    Write-Host "  Port file: $portFile"
    Write-Host "  Submodule path: $portPath"
    Write-Host "  GitHub URL: $portUrl"

    # Check if port directory exists
    if (-not (Test-Path $portDir)) {
        Write-Warning "  Port directory not found: $portDir"
        continue
    }

    # Get current commit hash
    $commitHash = Get-CurrentCommitHash -SubmodulePath $portPath
    if (-not $commitHash) {
        Write-Warning "  Failed to get commit hash for submodule"
        continue
    } else {
        Write-Host "  Current commit: $commitHash" -ForegroundColor Cyan
    }

    # Parse GitHub URL
    $repoInfo = Get-GitHubRepoInfo -GitUrl $portUrl
    if (-not $repoInfo) {
        Write-Warning "  Could not parse GitHub repository information"
        continue
    } else {
        Write-Host "  GitHub repo: $($repoInfo.Org)/$($repoInfo.Repo)" -ForegroundColor Cyan
    }

    # Call vcpkg to get the correct SHA512 for the download
    $sha512 = Get-SHA512FromVcpkg `
        -PortName $PortName `
        -Org $repoInfo.Org `
        -Repo $repoInfo.Repo `
        -CommitHash $CommitHash `
        -Branch $Branch
    if (-not $sha512) {
        Write-Warning "  Failed to get SHA512 hash"
    } else {
        Write-Host "  Download SHA512: $sha512" -ForegroundColor Cyan
    }

    # Update the actual port file
    if (Update-PortFile `
            -PortFilePath $portFile `
            -NewRef $commitHash `
            -NewSHA512 $sha512 `
            -Branch $submodule.Branch `
            -DryRun:$DryRun) {
        $updatedCount++
    }
}

Write-Host "`nSummary:" -ForegroundColor Blue
if ($DryRun) {
    Write-Host "Would update $updatedCount port files (dry run)" -ForegroundColor Yellow
}
else {
    Write-Host "Updated $updatedCount port files" -ForegroundColor Green
}

Write-Host "Script completed." -ForegroundColor Blue
