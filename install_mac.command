#!/bin/bash
# ==============================================================
# Adobe InDesign Armenian Hyphenation Installer for macOS
# ==============================================================

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

clear
echo "=========================================================="
echo "   Adobe InDesign Հայերեն Տողադարձման Տեղադրիչ (macOS)     "
echo "   Adobe InDesign Armenian Hyphenation Installer (macOS)  "
echo "=========================================================="
echo ""

# Switch to script directory
cd "$( dirname "${BASH_SOURCE[0]}" )"
SCRIPT_DIR="$( pwd )"
DIC_SOURCE="$SCRIPT_DIR/hyph_hy_AM.dic"

if [ ! -f "$DIC_SOURCE" ]; then
    echo "ՍԽԱԼ: hyph_hy_AM.dic նիշքը չի գտնվել: ($SCRIPT_DIR)"
    echo "ERROR: hyph_hy_AM.dic file not found."
    echo ""
    read -p "Սեղմեք Enter ավարտելու համար..."
    exit 1
fi

# Request sudo / admin privileges
if [ "$EUID" -ne 0 ]; then
    echo "Անհրաժեշտ են ադմինիստրատորի (sudo) իրավունքներ:"
    echo "Խնդրում ենք մուտքագրել Ձեր Mac-ի գաղտնաբառը (Password):"
    echo ""
    sudo "$0" "$@"
    exit $?
fi

echo "Որոնվում են տեղադրված InDesign տարբերակները..."

FOUND_ANY=0

while IFS= read -r -d '' PLUGIN_DIR; do
    FOUND_ANY=1
    APP_NAME=$(echo "$PLUGIN_DIR" | grep -o "Adobe InDesign[^/]*" | head -1)
    if [ -z "$APP_NAME" ]; then
        APP_NAME="Adobe InDesign"
    fi
    
    echo ""
    echo "[+] Գտնվեց: $APP_NAME"
    echo "    Ուղի: $PLUGIN_DIR"
    
    # Locate Dictionaries directory
    DICT_DIR="$PLUGIN_DIR/Dictionaries"
    if [ ! -d "$DICT_DIR" ]; then
        if [ -d "$PLUGIN_DIR/Contents/SharedSupport/Dictionaries" ]; then
            DICT_DIR="$PLUGIN_DIR/Contents/SharedSupport/Dictionaries"
        elif [ -d "$PLUGIN_DIR/Contents/Resources/Dictionaries" ]; then
            DICT_DIR="$PLUGIN_DIR/Contents/Resources/Dictionaries"
        fi
    fi
    mkdir -p "$DICT_DIR"
    
    # Create hy_AM folder
    HY_AM_DIR="$DICT_DIR/hy_AM"
    mkdir -p "$HY_AM_DIR"
    
    # Copy hyph_hy_AM.dic
    cp -f "$DIC_SOURCE" "$HY_AM_DIR/hyph_hy_AM.dic"
    chmod 644 "$HY_AM_DIR/hyph_hy_AM.dic"
    echo "    [OK] hyph_hy_AM.dic բառարանը պատճենվեց:"
    
    # Locate Info.plist
    PLIST_PATH="$PLUGIN_DIR/Info.plist"
    if [ ! -f "$PLIST_PATH" ]; then
        if [ -f "$PLUGIN_DIR/Contents/Info.plist" ]; then
            PLIST_PATH="$PLUGIN_DIR/Contents/Info.plist"
        elif [ -f "$PLUGIN_DIR/Contents/SharedSupport/Info.plist" ]; then
            PLIST_PATH="$PLUGIN_DIR/Contents/SharedSupport/Info.plist"
        fi
    fi
    
    if [ -f "$PLIST_PATH" ]; then
        BAK_PATH="${PLIST_PATH}.bak"
        if [ ! -f "$BAK_PATH" ]; then
            cp -f "$PLIST_PATH" "$BAK_PATH"
            echo "    [OK] Info.plist.bak պահուստային նիշքը ստեղծվեց:"
        fi
        
        # Check and update Info.plist via python3
        python3 -c "
import sys, re
path = '$PLIST_PATH'
try:
    with open(path, 'r', encoding='utf-8') as f:
        c = f.read()
    modified = False
    if 'hy_AM' not in c:
        if '<key>HyphenationService</key>' in c:
            c = re.sub(r'(<key>HyphenationService</key>\s*<array>)', r'\1\n\t\t\t<string>hy_AM</string>', c)
            modified = True
        if '<key>UserDictionaryService</key>' in c:
            c = re.sub(r'(<key>UserDictionaryService</key>\s*<array>)', r'\1\n\t\t\t<string>hy_AM</string>', c)
            modified = True
        if modified:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(c)
            print('    [OK] Info.plist-ը թարմացվեց (hy_AM ավելացված է):')
        else:
            print('    [!] Info.plist-ում կառուցվածքը չհամընկավ:')
    else:
        print('    [i] Info.plist-ում hy_AM արդեն առկա էր:')
except Exception as e:
    print('    [!] Սխալ Info.plist թարմացնելիս:', e)
"
    fi
done < <(find /Applications -maxdepth 6 -type d -name "AdobeHunspellPlugin*" -print0 2>/dev/null)

echo ""
if [ $FOUND_ANY -eq 0 ]; then
    echo "ՈՒՇԱԴՐՈՒԹՅՈՒՆ: /Applications թղթապանակում InDesign չգտնվեց:"
else
    echo "=========================================================="
    echo " ՏԵՂԱԴՐՈՒՄԸ ՀԱՋՈՂՈՒԹՅԱՄԲ ԱՎԱՐՏՎԵՑ!                       "
    echo " INSTALLATION COMPLETED SUCCESSFULLY!                    "
    echo "=========================================================="
    echo ""
    echo "InDesign-ում օգտագործելու համար`"
    echo "1. Բացեք InDesign-ը:"
    echo "2. Ընտրեք Preferences -> Dictionary -> Armenian (Hunspell):"
    echo "3. Character վահանակում ընտրեք Armenian, Paragraph-ում՝ Hyphenate:"
fi

echo ""
read -p "Սեղմեք Enter ավարտելու համար..."
