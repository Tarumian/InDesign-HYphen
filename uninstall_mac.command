#!/bin/bash
# ==============================================================
# Adobe InDesign Armenian Hyphenation Uninstaller for macOS
# ==============================================================

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

clear
echo "=========================================================="
echo "   Adobe InDesign Հայերեն Տողադարձման Հեռացուցիչ (macOS)  "
echo "   Adobe InDesign Armenian Hyphenation Uninstaller (macOS)"
echo "=========================================================="
echo ""

if [ "$EUID" -ne 0 ]; then
    echo "Անհրաժեշտ են ադմինիստրատորի (sudo) իրավունքներ:"
    echo "Խնդրում ենք մուտքագրել Ձեր Mac-ի գտնաբառը (Password):"
    echo ""
    sudo "$0" "$@"
    exit $?
fi

while IFS= read -r -d '' PLUGIN_DIR; do
    APP_NAME=$(echo "$PLUGIN_DIR" | grep -o "Adobe InDesign[^/]*" | head -1)
    if [ -z "$APP_NAME" ]; then
        APP_NAME="Adobe InDesign"
    fi
    
    echo "[+] Մշակվում է: $APP_NAME"
    
    # 1. Remove hy_AM folder
    find "$PLUGIN_DIR" -type d -name "hy_AM" -exec rm -rf {} + 2>/dev/null
    echo "    [OK] hy_AM թղթապանակը հեռացվեց:"
    
    # 2. Restore Info.plist from bak
    find "$PLUGIN_DIR" -name "Info.plist.bak" | while read -r BAK_FILE; do
        ORIG_FILE="${BAK_FILE%.bak}"
        cp -f "$BAK_FILE" "$ORIG_FILE"
        rm -f "$BAK_FILE"
        echo "    [OK] Info.plist-ը վերականգնվեց նախնական վիճակին:"
    done
done < <(find /Applications -maxdepth 6 -type d -name "AdobeHunspellPlugin*" -print0 2>/dev/null)

echo ""
echo "Ապատեղադրումն ավարտվեց:"
read -p "Սեղմեք Enter ավարտելու համար..."
