# Adobe InDesign Armenian Hyphenation Uninstaller
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = 'Adobe InDesign Armenian Hyphenation Uninstaller'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList ('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $PSCommandPath + '"'))
    exit
}

Clear-Host
Write-Host '========================================================' -ForegroundColor Cyan
Write-Host '   Adobe InDesign Հայերեն Տողադարձման Հեռացուցիչ (Uninstall) ' -ForegroundColor Yellow
Write-Host '========================================================' -ForegroundColor Cyan
Write-Host ''

$searchPaths = @('C:\Program Files\Adobe', 'C:\Program Files (x86)\Adobe')

foreach ($basePath in $searchPaths) {
    if (Test-Path $basePath) {
        $idDirs = Get-ChildItem -Path $basePath -Directory -Filter '*InDesign*' -ErrorAction SilentlyContinue
        foreach ($idDir in $idDirs) {
            $pluginDirs = Get-ChildItem -Path $idDir.FullName -Directory -Filter 'AdobeHunspellPlugin' -Recurse -ErrorAction SilentlyContinue
            foreach ($pDir in $pluginDirs) {
                Write-Host "[+] Մշակվում է: $($idDir.Name)" -ForegroundColor Yellow
                
                # 1. Remove Dictionaries\hy_AM
                $hyAmDir = Join-Path $pDir.FullName 'Dictionaries\hy_AM'
                if (Test-Path $hyAmDir) {
                    Remove-Item -Path $hyAmDir -Recurse -Force
                    Write-Host '    [OK] hy_AM թղթապանակը հեռացվեց:' -ForegroundColor Green
                }
                
                # 2. Restore Info.plist from backup if exists
                $bakPath = Join-Path $pDir.FullName 'Info.plist.bak'
                $plistPath = Join-Path $pDir.FullName 'Info.plist'
                if (Test-Path $bakPath) {
                    Copy-Item -Path $bakPath -Destination $plistPath -Force
                    Remove-Item -Path $bakPath -Force
                    Write-Host '    [OK] Info.plist ֆայլը վերականգնվեց նախնական վիճակին:' -ForegroundColor Green
                }
            }
        }
    }
}

Write-Host ''
Write-Host 'Ապատեղադրումն ավարտվեց: Սեղմեք որևէ ստեղն...' -ForegroundColor Green
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
