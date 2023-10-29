#!/usr/bin/env fish

function check_var -a var msg
    if test -z $var; echo $msg >&2; exit 1; end
end

function check_status -a msg
    if test $status != 0; echo $msg >&2; exit 1; end
end

function check_file -a file
    if not test -e $file; echo "$file not found" >&2; exit 1; end
end

function get_file -a repo pattern
    set -l ver (curl -s "https://github.com/$repo/releases" | grep 'releases/tag' |\
                string match -rg 'releases/tag/(.*?)"' | sed 's/%2F/-/g' | head -1)
    check_var "$ver" "$repo version not found"
    echo "found $repo version" $ver >&2

    set -l filename (curl -s "https://github.com/$repo/releases/expanded_assets/$ver" |\
                     string match -rg "($pattern)" | head -1)
    check_var "$filename" "$repo $ver $pattern not found"
    echo "found $filename" >&2

    if not test -e $filename
       curl -s -OL "https://github.com/$repo/releases/download/$ver/$filename"
    end
    echo $filename
end

# setup dir
set -l pack pack
if test -e $pack
    rm -r $pack
end

# hekate
set -l HEKATE_ZIP (get_file 'CTCaer/hekate' "hekate_.*?\.zip")
unzip -q $HEKATE_ZIP -d $pack
check_status "$HEKATE_ZIP unzip failed"
check_file "$pack/bootloader"
mv $pack/hekate_ctcaer_*.bin $pack/payload.bin

# copy sx gears boot files
cp boot_files/boot.{dat,ini} $pack/

# generate boot.dat from hekate
# curl -s -L https://gist.githubusercontent.com/CTCaer/13c02c05daec9e674ba00ce5ac35f5be/raw/tx_custom_boot.py |\
# 	     sed "s/boot_fn = .*/boot_fn = \"$pack\/boot.dat\"/; \
# 	     s/stage2_fn = .*/stage2_fn = \"$pack\/payload.bin\"/" | python3 -
# check_file "$pack/boot.dat"
# echo -e '[payload]\nfile=payload.bin' > $pack/boot.ini

# atmosphere
set -l ATMOSPHERE_ZIP (get_file 'Atmosphere-NX/Atmosphere' "atmosphere-.*?\.zip")
unzip -q $ATMOSPHERE_ZIP -d $pack
check_status "$ATMOSPHERE_ZIP unzip failed"
check_file "$pack/atmosphere"

# block dns
mkdir -p $pack/atmosphere/hosts
curl -s -L https://nh-server.github.io/switch-guide/files/emummc.txt -o $pack/atmosphere/hosts/emummc.txt
check_file "$pack/atmosphere/hosts/emummc.txt"

# fusee.bin
get_file 'Atmosphere-NX/Atmosphere' "fusee\.bin"
cp fusee.bin $pack/bootloader/payloads/
check_file "$pack/bootloader/payloads/fusee.bin"

# atmosphere configs
cat $pack/atmosphere/config_templates/exosphere.ini |\
    sed '/^#.*$/d; /^[[:space:]]*$/d; s/\(blank.*mmc\)=0/\\1=1/' \
    > $pack/exosphere.ini
cat $pack/atmosphere/config_templates/system_settings.ini |\
    sed 's/; \(usb30_force_enabled\).*/\\1 = u8!0x1/;
         s/; \(dmnt_cheats_enabled_by_default\).*/\\1 = u8!0x0/; s/\r//' |\
    sed 's/\(\[atmosphere\]\)/\\1\nenable_standalone_gdbstub = u8!0x1/' \
    > $pack/atmosphere/config/system_settings.ini

# hekate stuffs
cp hekate_resources/{sysnand,emummc}.bmp $pack/bootloader/res/
cp hekate_resources/hekate_ipl.ini $pack/bootloader/

# lockpick_RCM
# get_file 'shchmue/Lockpick_RCM' "Lockpick_RCM\.bin" > /dev/null
# cp Lockpick_RCM.bin $pack/bootloader/payloads/
# check_file "$pack/bootloader/payloads/Lockpick_RCM.bin"
curl -s -L https://git.disroot.org/Lockpick/Binaries/raw/branch/main/Lockpick_RCM.bin \
     -o $pack/bootloader/payloads/Lockpick_RCM.bin
check_file "$pack/bootloader/payloads/Lockpick_RCM.bin"

# hwfly-toolbox
# get_file 'hwfly-nx/hwfly-toolbox' "hwfly_toolbox\.bin" > /dev/null
# cp hwfly_toolbox.bin $pack/bootloader/payloads/
# check_file "$pack/bootloader/payloads/hwfly_toolbox.bin"

# sigmapatches
curl -s -OL https://sigmapatches.coomer.party/sigpatches.zip
unzip -q sigpatches.zip -d $pack
check_status "sigpatches.zip unzip failed"
check_file "$pack/bootloader/patches.ini"

# DBI
get_file 'rashevskyv/dbi' 'DBI\.nro' > /dev/null
get_file 'rashevskyv/dbi' 'dbi\.config' > /dev/null
mkdir -p $pack/switch/DBI
cp {DBI.nro,dbi.config} $pack/switch/DBI/
check_file "$pack/switch/DBI/DBI.nro"

# nx-shell
get_file 'joel16/NX-Shell' 'NX-Shell\.nro' > /dev/null
cp NX-Shell.nro $pack/switch/
check_file "$pack/switch/NX-Shell.nro"

# nx-ovlloader
get_file 'WerWolv/nx-ovlloader' 'nx-ovlloader\.zip' > /dev/null
unzip -q nx-ovlloader.zip -d $pack
check_status "nx-ovlloader.zip unzip failed"
check_file "$pack/atmosphere/contents/420000000007E51A"

# tesla-menu
get_file 'WerWolv/Tesla-Menu' 'ovlmenu\.zip' > /dev/null
unzip -q ovlmenu.zip -d $pack
check_status "ovlmenu.zip unzip failed"
check_file "$pack/switch/.overlays/ovlmenu.ovl"

# ovlEdiZon
get_file 'proferabg/EdiZon-Overlay' 'EdiZon-Overlay\.zip' > /dev/null
unzip -q EdiZon-Overlay.zip -d $pack
check_file "$pack/switch/.overlays/ovlEdiZon.ovl"

# EdiZon SE
get_file 'tomvita/EdiZon-SE' 'EdiZon\.zip' > /dev/null
unzip -q EdiZon.zip -d $pack
check_file "$pack/switch/EdiZon/EdiZon.nro"

# Breeze
get_file 'tomvita/Breeze-Beta' 'Breeze\.zip' > /dev/null
unzip -q -o Breeze.zip -d $pack
check_status "Breeze.zip unzip failed"
check_file "$pack/switch/breeze/Breeze.nro"

# Status-Monitor-Overlay
get_file 'masagrator/Status-Monitor-Overlay' 'Status-Monitor-Overlay\.ovl' > /dev/null
cp Status-Monitor-Overlay.ovl $pack/switch/.overlays/
check_file "$pack/switch/.overlays/Status-Monitor-Overlay.ovl"

# linkalho
set -l LINKALHO_ZIP (get_file 'rdmrocha/linkalho' "linkalho-.*?\.zip")
unzip -q -o $LINKALHO_ZIP -d $pack/switch/
check_status "$LINKALHO_ZIP unzip failed"
check_file "$pack/switch/linkalho.nro"

# emuiibo
get_file 'XorTroll/emuiibo' 'emuiibo\.zip' > /dev/null
unzip -q -o emuiibo.zip -d .
check_file "SdOut"
cp -r SdOut/* $pack/
rm -r SdOut
check_file "$pack/switch/.overlays/emuiibo.ovl"
