#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import sys
import glob
import shutil
import re
import subprocess

def run_as_root():
    if os.geteuid() != 0:
        print('Անհրաժեշտ են ադմինիստրատորի (sudo) իրավունքներ:')
        print('Խնդրում ենք մուտքագրել Ձեր Mac-ի գաղտնաբառը (Password):\n')
        try:
            # Re-run current script with sudo
            ret = subprocess.call(['sudo', sys.executable] + sys.argv)
            sys.exit(ret)
        except Exception as e:
            print('Սխալ sudo գործարկելիս:', e)
            input('\nՍեղմեք Enter ավարտելու համար...')
            sys.exit(1)

def main():
    print('=' * 58)
    print('   Adobe InDesign Հայերեն Տողադարձման Տեղադրիչ (macOS)   ')
    print('   Adobe InDesign Armenian Hyphenation Installer (macOS) ')
    print('=' * 58)
    print()

    script_dir = os.path.dirname(os.path.abspath(__file__))
    dic_source = os.path.join(script_dir, 'hyph_hy_AM.dic')

    if not os.path.isfile(dic_source):
        print(f'ՍԽԱԼ: hyph_hy_AM.dic նիշքը չի գտնվել: ({script_dir})')
        print('ERROR: hyph_hy_AM.dic file not found.\n')
        input('Սեղմեք Enter ավարտելու համար...')
        sys.exit(1)

    run_as_root()

    print('Որոնվում են տեղադրված InDesign տարբերակները...\n')

    # Search for AdobeHunspellPlugin inside /Applications
    plugin_dirs = []
    app_base = '/Applications'
    if os.path.exists(app_base):
        for root, dirs, files in os.walk(app_base):
            depth = root[len(app_base):].count(os.sep)
            if depth > 6:
                dirs.clear()
                continue
            for d in list(dirs):
                if 'AdobeHunspellPlugin' in d:
                    plugin_dirs.append(os.path.join(root, d))
                    dirs.remove(d)

    if not plugin_dirs:
        print('ՈՒՇԱԴՐՈՒԹՅՈՒՆ: /Applications թղթապանակում InDesign չգտնվեց:')
    else:
        for plugin_dir in plugin_dirs:
            app_match = re.search(r'Adobe InDesign[^/]*', plugin_dir)
            app_name = app_match.group(0) if app_match else 'Adobe InDesign'
            print(f'[+] Գտնվեց: {app_name}')
            print(f'    Ուղի: {plugin_dir}')

            # Locate Dictionaries directory
            dict_dir = os.path.join(plugin_dir, 'Dictionaries')
            if not os.path.isdir(dict_dir):
                for sub in ['Contents/SharedSupport/Dictionaries', 'Contents/Resources/Dictionaries']:
                    candidate = os.path.join(plugin_dir, sub.replace('/', os.sep))
                    if os.path.isdir(candidate):
                        dict_dir = candidate
                        break

            os.makedirs(dict_dir, exist_ok=True)
            hy_dir = os.path.join(dict_dir, 'hy_AM')
            os.makedirs(hy_dir, exist_ok=True)

            target_dic = os.path.join(hy_dir, 'hyph_hy_AM.dic')
            shutil.copy2(dic_source, target_dic)
            os.chmod(target_dic, 0o644)
            print('    [OK] hyph_hy_AM.dic բառարանը պատճենվեց:')

            # Locate Info.plist
            plist_candidates = [
                os.path.join(plugin_dir, 'Info.plist'),
                os.path.join(plugin_dir, 'Contents', 'Info.plist'),
                os.path.join(plugin_dir, 'Contents', 'SharedSupport', 'Info.plist')
            ]
            plist_path = None
            for p in plist_candidates:
                if os.path.isfile(p):
                    plist_path = p
                    break

            if plist_path:
                bak_path = plist_path + '.bak'
                if not os.path.exists(bak_path):
                    shutil.copy2(plist_path, bak_path)
                    print('    [OK] Info.plist.bak պահուստային նիշքը ստեղծվեց:')

                try:
                    with open(plist_path, 'r', encoding='utf-8') as f:
                        c = f.read()

                    if 'hy_AM' not in c:
                        modified = False
                        if '<key>HyphenationService</key>' in c:
                            c = re.sub(r'(<key>HyphenationService</key>\s*<array>)', r'\1\n\t\t\t<string>hy_AM</string>', c)
                            modified = True
                        if '<key>UserDictionaryService</key>' in c:
                            c = re.sub(r'(<key>UserDictionaryService</key>\s*<array>)', r'\1\n\t\t\t<string>hy_AM</string>', c)
                            modified = True
                        if modified:
                            with open(plist_path, 'w', encoding='utf-8') as f:
                                f.write(c)
                            print('    [OK] Info.plist-ը թարմացվեց (hy_AM ավելացված է):')
                        else:
                            print('    [!] Info.plist-ում կառուցվածքը չհամընկավ:')
                    else:
                        print('    [i] Info.plist-ում hy_AM արդեն առկա էր:')
                except Exception as e:
                    print('    [!] Սխալ Info.plist թարմացնելիս:', e)
            print()

        print('=' * 58)
        print(' ՏԵՂԱԴՐՈՒՄԸ ՀԱՋՈՂՈՒԹՅԱՄԲ ԱՎԱՐՏՎԵՑ!                       ')
        print(' INSTALLATION COMPLETED SUCCESSFULLY!                    ')
        print('=' * 58)
        print()
        print('InDesign-ում օգտագործելու համար')
        print('1. Բացեք InDesign-ը:')
        print('2. Ընտրեք Preferences -> Dictionary -> Armenian (Hunspell):')
        print('3. Character վահանակում ընտրեք Armenian, Paragraph-ում՝ Hyphenate:')

    print()
    input('Սեղմեք Enter ավարտելու համար...')

if __name__ == '__main__':
    main()
