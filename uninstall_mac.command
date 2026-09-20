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
            ret = subprocess.call(['sudo', sys.executable] + sys.argv)
            sys.exit(ret)
        except Exception as e:
            print('Սխալ sudo գործարկելիս:', e)
            input('\nՍեղմեք Enter ավարտելու համար...')
            sys.exit(1)

def main():
    print('=' * 58)
    print('   Adobe InDesign Հայերեն Տողադարձման Հեռացուցիչ (macOS)  ')
    print('   Adobe InDesign Armenian Hyphenation Uninstaller (macOS)')
    print('=' * 58)
    print()

    run_as_root()

    print('Որոնվում են InDesign թղթապանակները...\n')

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
        print('Համապատասխան InDesign թղթապանակներ չգտնվեցին:')
    else:
        for plugin_dir in plugin_dirs:
            app_match = re.search(r'Adobe InDesign[^/]*', plugin_dir)
            app_name = app_match.group(0) if app_match else 'Adobe InDesign'
            print(f'[+] Մշակվում է: {app_name}')

            # 1. Remove hy_AM folder
            for root, dirs, files in os.walk(plugin_dir):
                for d in list(dirs):
                    if d == 'hy_AM':
                        target = os.path.join(root, d)
                        shutil.rmtree(target, ignore_errors=True)
                        print('    [OK] hy_AM թղթապանակը հեռացվեց:')

            # 2. Restore Info.plist from bak
            for root, dirs, files in os.walk(plugin_dir):
                for f in files:
                    if f == 'Info.plist.bak':
                        bak_file = os.path.join(root, f)
                        orig_file = os.path.join(root, 'Info.plist')
                        shutil.copy2(bak_file, orig_file)
                        os.remove(bak_file)
                        print('    [OK] Info.plist-ը վերականգնվեց նախնական վիճակին:')
            print()

        print('=' * 58)
        print(' ԱՊԱՏԵՂԱԴՐՈՒՄՆ ԱՎԱՐՏՎԵՑ!                                 ')
        print(' UNINSTALLATION COMPLETED!                               ')
        print('=' * 58)

    print()
    input('Սեղմեք Enter ավարտելու համար...')

if __name__ == '__main__':
    main()
