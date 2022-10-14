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
    set -l ver (curl --silent "https://github.com/$repo/releases" | grep 'releases/tag' |\
                string match -rg 'releases/tag/(.*?)"' | sed 's/%2F/-/g' | head -1)
    check_var "$ver" "$repo version not found"
    echo "found $repo version" $ver >&2

    set -l filename (curl --silent "https://github.com/$repo/releases/expanded_assets/$ver" |\
                     string match -rg "($pattern)" | head -1)
    check_var "$filename" "$repo $ver $pattern not found"
    echo "found $filename" >&2

    if not test -e $filename
       curl -OL "https://github.com/$repo/releases/download/$ver/$filename"
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
unzip $HEKATE_ZIP -d $pack
check_status "$HEKATE_ZIP unzip failed"
check_file "$pack/bootloader"
mv $pack/hekate_ctcaer_*.bin $pack/payload.bin

# atmosphere
set -l ATMOSPHERE_ZIP (get_file 'Atmosphere-NX/Atmosphere' "atmosphere-.*?\.zip")
unzip $ATMOSPHERE_ZIP -d $pack
check_status "$ATMOSPHERE_ZIP unzip failed"
check_file "$pack/atmosphere"

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
         s/; \(dmnt_cheats_enabled_by_default\).*/\\1 = u8!0x0/; s/\r//' \
    > $pack/atmosphere/config/system_settings.ini

# hekate stuffs
cp hekate_resources/{sysnand,emummc}.bmp $pack/bootloader/res/
cp hekate_resources/hekate_ipl.ini $pack/bootloader/

# lockpick_RCM
get_file 'shchmue/Lockpick_RCM' "Lockpick_RCM\.bin" > /dev/null
cp Lockpick_RCM.bin $pack/bootloader/payloads/
check_file "$pack/bootloader/payloads/Lockpick_RCM.bin"

# boot files
cp boot_files/boot.{dat,ini} $pack/

# sigmapatches
if not test -e sigpatches.zip
    curl -OL https://sigmapatches.coomer.party/sigpatches.zip
end
unzip sigpatches.zip -d $pack
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
unzip nx-ovlloader.zip -d $pack
check_status "nx-ovlloader.zip unzip failed"
check_file "$pack/atmosphere/contents/420000000007E51A"

# tesla-menu
get_file 'WerWolv/Tesla-Menu' 'ovlmenu\.zip' > /dev/null
unzip ovlmenu.zip -d $pack
check_status "ovlmenu.zip unzip failed"
check_file "$pack/switch/.overlays/ovlmenu.ovl"

# EdiZon
get_file 'WerWolv/EdiZon' 'EdiZon\.nro' > /dev/null
get_file 'WerWolv/EdiZon' 'ovlEdiZon\.ovl' > /dev/null
mkdir -p $pack/switch/EdiZon
cp EdiZon.nro $pack/switch/EdiZon/
cp ovlEdiZon.ovl $pack/switch/.overlays/
check_file "$pack/switch/EdiZon/EdiZon.nro"
check_file "$pack/switch/.overlays/ovlEdiZon.ovl"

# breeze
get_file 'tomvita/Breeze-Beta' 'Breeze\.zip' > /dev/null
unzip Breeze.zip -d $pack
check_status "Breeze.zip unzip failed"
check_file "$pack/switch/breeze/Breeze.nro"

# Status-Monitor-Overlay
get_file 'masagrator/Status-Monitor-Overlay' 'Status-Monitor-Overlay\.ovl' > /dev/null
cp Status-Monitor-Overlay.ovl $pack/switch/.overlays/
check_file "$pack/switch/.overlays/Status-Monitor-Overlay.ovl"
