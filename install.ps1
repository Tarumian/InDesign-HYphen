# Adobe InDesign Armenian Hyphenation Installer
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = 'Adobe InDesign Armenian Hyphenation Installer'

# Check for Admin Privileges and elevate if necessary
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host 'Անհրաժեշտ են ադմինիստրատորի իրավունքներ: Բացվում է UAC հարցումը...' -ForegroundColor Yellow
    Write-Host 'Requesting Administrator privileges...' -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList ('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $PSCommandPath + '"'))
    exit
}

Clear-Host
Write-Host '========================================================' -ForegroundColor Cyan
Write-Host '   Adobe InDesign Հայերեն Տողադարձման Տեղադրիչ          ' -ForegroundColor Green
Write-Host '   Adobe InDesign Armenian Hyphenation Installer        ' -ForegroundColor Green
Write-Host '========================================================' -ForegroundColor Cyan
Write-Host ''

$scriptDir = Split-Path -Parent $PSCommandPath
$dicSource = Join-Path $scriptDir 'hyph_hy_AM.dic'

if (-not (Test-Path $dicSource)) {
    Write-Host "ՍԽԱԼ: hyph_hy_AM.dic ֆայլը չի գտնվել $scriptDir թղթապանակում:" -ForegroundColor Red
    pause
    exit
}

$searchPaths = @('C:\Program Files\Adobe', 'C:\Program Files (x86)\Adobe')
$foundAny = $false

foreach ($basePath in $searchPaths) {
    if (Test-Path $basePath) {
        $idDirs = Get-ChildItem -Path $basePath -Directory -Filter '*InDesign*' -ErrorAction SilentlyContinue
        foreach ($idDir in $idDirs) {
            $pluginDirs = Get-ChildItem -Path $idDir.FullName -Directory -Filter 'AdobeHunspellPlugin' -Recurse -ErrorAction SilentlyContinue
            foreach ($pDir in $pluginDirs) {
                $foundAny = $true
                Write-Host "[+] Գտնվեց InDesign: $($idDir.Name)" -ForegroundColor Yellow
                Write-Host "    Ուղի: $($pDir.FullName)" -ForegroundColor Gray
                
                # 1. Create Dictionaries\hy_AM folder
                $dictDir = Join-Path $pDir.FullName 'Dictionaries'
                if (-not (Test-Path $dictDir)) {
                    New-Item -ItemType Directory -Path $dictDir -Force | Out-Null
                }
                $hyAmDir = Join-Path $dictDir 'hy_AM'
                if (-not (Test-Path $hyAmDir)) {
                    New-Item -ItemType Directory -Path $hyAmDir -Force | Out-Null
                }
                
                # Copy hyph_hy_AM.dic
                $targetDic = Join-Path $hyAmDir 'hyph_hy_AM.dic'
                Copy-Item -Path $dicSource -Destination $targetDic -Force
                Write-Host '    [OK] hyph_hy_AM.dic բառարանը պատճենվեց:' -ForegroundColor Green
                
                # 2. Update Info.plist
                $plistPath = Join-Path $pDir.FullName 'Info.plist'
                if (Test-Path $plistPath) {
                    $bakPath = Join-Path $pDir.FullName 'Info.plist.bak'
                    if (-not (Test-Path $bakPath)) {
                        Copy-Item -Path $plistPath -Destination $bakPath -Force
                        Write-Host '    [OK] Info.plist.bak պահուստային ֆայլը ստեղծվեց:' -ForegroundColor Green
                    }
                    
                    [string]$content = [System.IO.File]::ReadAllText($plistPath, [System.Text.Encoding]::UTF8)
                    $modified = $false
                    
                    # HyphenationService check
                    if ($content -notmatch 'HyphenationService[\s\S]*?<string>hy_AM</string>') {
                        $patternHyphen = '(<key>HyphenationService</key>\s*<array>)'
                        if ($content -match $patternHyphen) {
                            $content = $content -replace $patternHyphen, "`$1`r`n`t`t`t<string>hy_AM</string>"
                            $modified = $true
                        }
                    }
                    
                    # UserDictionaryService check
                    if ($content -match '<key>UserDictionaryService</key>' -and $content -notmatch 'UserDictionaryService[\s\S]*?<string>hy_AM</string>') {
                        $patternUserDict = '(<key>UserDictionaryService</key>\s*<array>)'
                        if ($content -match $patternUserDict) {
                            $content = $content -replace $patternUserDict, "`$1`r`n`t`t`t<string>hy_AM</string>"
                            $modified = $true
                        }
                    }
                    
                    if ($modified) {
                        [System.IO.File]::WriteAllText($plistPath, $content, [System.Text.Encoding]::UTF8)
                        Write-Host '    [OK] Info.plist-ը հաջողությամբ թարմացվեց:' -ForegroundColor Green
                    } else {
                        Write-Host '    [i] Info.plist-ում hy_AM արդեն առկա էր:' -ForegroundColor Cyan
                    }
                }
                Write-Host ''
            }
        }
    }
}

if (-not $foundAny) {
    Write-Host 'ՈՒՇԱԴՐՈՒԹՅՈՒՆ: InDesign-ի տեղադրված տարբերակ չգտնվեց:' -ForegroundColor Red
} else {
    Write-Host '========================================================' -ForegroundColor Cyan
    Write-Host ' ՏԵՂԱԴՐՈՒՄԸ ՀԱՋՈՂՈՒԹՅԱՄԲ ԱՎԱՐՏՎԵՑ!                      ' -ForegroundColor Green
    Write-Host ' INSTALLATION COMPLETED SUCCESSFULLY!                   ' -ForegroundColor Green
    Write-Host '========================================================' -ForegroundColor Cyan
    Write-Host 'InDesign-ում կարգավորելու համար`' -ForegroundColor Yellow
    Write-Host '1. Բացեք InDesign-ը:' -ForegroundColor White
    Write-Host '2. Ընտրեք Edit -> Preferences -> Dictionary:' -ForegroundColor White
    Write-Host '3. Language բաժնում ընտրեք Armenian (Hyphenation: Hunspell):' -ForegroundColor White
    Write-Host '4. Paragraph վահանակում միացրեք Hyphenate նշիչը:' -ForegroundColor White
}

Write-Host ''
Write-Host 'Սեղմեք որևէ ստեղն ավարտելու համար...'
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
