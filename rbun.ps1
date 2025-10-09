#Requires -Version 5.1

param ()

$scriptRoot = "C:/Users/tarun/CodingProjects/nt/scripts"
$taskDefinitions = @{
    "glossary" = @{ Path = "$scriptRoot/rules.ts" }
    "find"     = @{ Path = "$scriptRoot/finder.ts" }
    "replace"  = @{ Path = "$scriptRoot/replace.ts" }
    "code"     = @{ } # Special task for editing other scripts
}

$tasksToRun = $taskDefinitions.Keys | Where-Object { $_ -ne 'code' }
$taskName = $null
$scriptToEdit = $null
$remainingArgs = @()

function Show-Menu {
    Write-Host "Please select a task to run:" -ForegroundColor Cyan
    $menuItems = $taskDefinitions.Keys | Sort-Object
    for ($i = 0; $i -lt $menuItems.Count; $i++) {
        Write-Host "  $($i + 1)) $($menuItems[$i])"
    }
    Write-Host ""
    
    $selection = Read-Host "Enter choice (1-$($menuItems.Count))"
    
    if ([int]::TryParse($selection, [ref][int]$index) -and $index -gt 0 -and $index -le $menuItems.Count) {
        return $menuItems[$index - 1]
    }
    else {
        Write-Host "Invalid selection." -ForegroundColor Red
        return $null
    }
}

function Get-TaskArguments ($selectedTask) {
    switch ($selectedTask) {
        "find" {
            $searchTerm = Read-Host "Enter search pattern (required)"
            if ([string]::IsNullOrEmpty($searchTerm)) {
                Write-Host "Search pattern is required. Aborting." -ForegroundColor Red
                return $null
            }
            $scriptArgs = @($searchTerm)
            
            $otherFlags = Read-Host "Enter additional flags (optional) (e.g., -o 'file.txt' --regex)"
            if (-not [string]::IsNullOrEmpty($otherFlags)) {
                $scriptArgs += $otherFlags -split ' ' | Where-Object { $_.Length -gt 0 }
            }
            return $scriptArgs
        }
        "replace" {
            Write-Host "Enter new values, or press Enter to use defaults."
            $search = Read-Host "  Search Pattern (default: 'Dusian')"
            $replace = Read-Host "  Replacement (default: 'Capital Immortals')"
            
            $scriptArgs = @()
            if (-not [string]::IsNullOrEmpty($search)) { $scriptArgs += "--search_pattern", $search }
            if (-not [string]::IsNullOrEmpty($replace)) { $scriptArgs += "--replacement", $replace }
            return $scriptArgs
        }
        "code" {
            $validScripts = $tasksToRun -join ', '
            $editTarget = Read-Host "Enter the script to edit ($validScripts)"
            if (-not $tasksToRun.Contains($editTarget)) {
                Write-Host "Invalid script name. Aborting." -ForegroundColor Red
                return $null
            }
            $script:scriptToEdit = $editTarget
            return @()
        }
        default {
            return @()
        }
    }
}

if ($args.Count -gt 0) {
    $taskName = $args[0]
    if (-not $taskDefinitions.ContainsKey($taskName)) {
        Write-Host "Error: Invalid task name '$taskName'." -ForegroundColor Red
        $taskName = $null
    }
    elseif ($taskName -eq "code") {
        if ($args.Count -gt 1 -and $tasksToRun.Contains($args[1])) {
            $scriptToEdit = $args[1]
        }
        else {
            Write-Host "Error: A valid script name must be provided for 'code'." -ForegroundColor Red
            Write-Host "Available scripts: $($tasksToRun -join ', ')"
            $taskName = $null
        }
    }
    else {
        if ($args.Count -gt 1) {
            $remainingArgs = $args[1..($args.Count - 1)]
        }
    }
}
else {
    $taskName = Show-Menu
    if ($taskName) {
        $remainingArgs = Get-TaskArguments $taskName
        if ($null -eq $remainingArgs) {
            $taskName = $null
        }
    }
}

if ([string]::IsNullOrEmpty($taskName)) {
    Write-Host "No valid task selected. Exiting." -ForegroundColor Yellow
    return
}

Write-Host "`nAttempting to execute task: $taskName" -ForegroundColor Yellow

if ($taskName -eq 'code') {
    $scriptPath = $taskDefinitions[$scriptToEdit].Path
    Write-Host "Opening '$scriptToEdit' in VS Code..." -ForegroundColor Gray
    code $scriptPath
}
else {
    $scriptPath = $taskDefinitions[$taskName].Path
    $argString = $remainingArgs -join ' '
    if ($argString) { Write-Host "With args: $argString" -ForegroundColor Gray }
    
    bun run $scriptPath $remainingArgs
}

Write-Host "Task '$taskName' finished." -ForegroundColor Green