#! /usr/bin/env bash

firefox_install_paths=(
    ~/.mozilla/firefox
    ~/.var/app/org.mozilla.firefox/.mozilla/firefox
    ~/.var/app/org.mozilla.FirefoxNightly/.mozilla/firefox
    ~/snap/firefox/common/.mozilla/firefox
)

installpathcount=0
foundprofilesfilecount=0
foundprofilespathcount=0

echo "$PWD is working direcory"

if [ ! -d "$PWD/.git" ]; then
    echo "ERROR: Not in git root. Exiting"
    exit 1
fi

if [ -d "$PWD/.git" ]; then
    dir="$PWD"
fi

if [ ! -f "$PWD/user.js" ]; then
    echo "ERROR: user.js file not found. Exiting"
    exit 1
fi

if [ ! -f "$PWD/package.json" ]; then
    echo "ERROR: package.json file not found. Exiting"
    exit 1
fi

if which git >/dev/null; then
    echo "SUCCESS: git found"
    cd "$PWD" && git submodule update --init --recursive || true
else
    echo "ERROR: git not found. Exiting"
    exit 1
fi


if which npm >/dev/null; then
    echo "SUCCESS: npm found"
else
    echo "ERROR: npm not found. Exiting"
    exit 1
fi

if which npx >/dev/null; then
    echo "SUCCESS: npx found"
else
    echo "FAIL: npx not found"
    npm install -g npx
fi

if [ -f "$PWD/package.json" ]; then
    npm install && npm run build
fi

if [ ! -d "$PWD/chrome" ]; then
    echo "ERROR: chrome folder not found. Exiting"
    exit 1
fi

for path in "${firefox_install_paths[@]}"; do
    if [ -d "$path" ]; then
        echo "SUCCESS: Firefox installation path found at $path" >&2
        (( installpathcount+=1 ))
        mapfile -t found_firefox_install_paths < <( echo "$path" )
    fi
done

if [ $installpathcount == 0 ]; then
    echo "FAIL: No Firefox installation path found at $path" >&2
    exit 1
fi

for found_path in "${found_firefox_install_paths[@]}"; do
    if [ -f "${found_path}/profiles.ini" ]; then
        echo "SUCCESS: profiles.ini found in ${found_path}" >&2
        (( foundprofilesfilecount+=1 ))
        mapfile -t found_profiles_file < <( echo "${found_path}/profiles.ini" )
    fi
done

if [ $foundprofilesfilecount == 0 ]; then
    echo "FAIL: Could not find profiles.ini" >&2
    exit 1
fi

for profiles_file in "${found_profiles_file[@]}"; do
    mapfile -t found_profile_paths < <( grep -E "^Path=" "${profiles_file}"| tr -d '\n'|sed -e 's/\s\+/SPACECHARACTER/g' | sed 's/Path=//g' )
done

for profiles_path in "${found_profile_paths[@]}"; do
    if [ -d "${profiles_path}" ]; then
        echo "SUCCESS: Profile path found at ${profiles_path}" >&2
        (( foundprofilespathcount+=1 ))
        echo "Copying chrome folder" >&2
        cp -fR "$dir/chrome" "${profiles_path}"
        echo "Setting user.js file" >&2
        mapfile -t theme_prefs < <( grep "user_pref" "$dir/user.js" )
        mapfile -t theme_prefs_unvalued < <( grep "user_pref" "$dir/user.js"|cut -d'"' -f 2 )
        if [ ! -f "${profiles_path}/user.js" ]; then
            echo "Existing user.js not found" >&2
            cp -f "$dir/user.js" "${profiles_path}"
        else
            echo "Existing user.js found. Backing up" >&2
            cp "${profiles_path}/user.js" "${profiles_path}/user.js.bak.txt"
            OLDIFS=$IFS
            IFS='/'
            for t in "${theme_prefs_unvalued[@]}"; do
                sed -i "/$t/d" "${profiles_path}/user.js"
            done
            for f in "${theme_prefs[@]}"; do
                echo "$f" >> "${profiles_path}/user.js"
            done
            IFS=$OLDIFS
        fi
    fi
    echo "SUCCESS: Theme installed" >&2
done

if [ $foundprofilespathcount == 0 ]; then
    echo "FAIL: Profile folder not found" >&2
    echo "FAIL: Theme not installed" >&2
    exit 1
fi
