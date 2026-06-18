#!/bin/bash

check_env(){
OS_ID_TYPE=$(cat /etc/os-release | grep -m 1 -o -P '(?<=ID=).*')
OS_LIKE_ID_TYPE=$(cat /etc/os-release | grep -m 1 -o -P '(?<=ID_LIKE=).*' || true)

if [[ "$OS_ID_TYPE" = "arch" ]] || [[ "$OS_LIKE_ID_TYPE" = "arch" ]]; then
if [[ $i = "y" ]] && [[ $u = "n" ]]; then
echo "--------------------------------------------------------"
echo "Please do not use this script to install gnome-rounded-blur on Arch Linux"
echo "To install this library on Arch, please do so via the AUR"
echo "https://aur.archlinux.org/packages/gnome-rounded-blur"
echo "--------------------------------------------------------"
elif [[ $i = "n" ]] && [[ $u = "y" ]]; then
echo "--------------------------------------------------------"
echo "Please do not use this script to uninstall gnome-rounded-blur on Arch Linux"
echo "To uninstall this library on Arch, please use the following command"
echo "< sudo pacman -R gnome-rounded-blur >"
echo "--------------------------------------------------------"
fi
sleep 5
exit 1
fi
}

install_git(){
if ! command -v git >/dev/null 2>&1; then
if [[ "$OS_ID_TYPE" = "debian" ]] || [[ "$OS_LIKE_ID_TYPE" = "debian" ]]; then
sudo apt -y install git
elif [[ "$OS_ID_TYPE" = "fedora" ]] || [[ "$OS_LIKE_ID_TYPE" = "fedora" ]]; then
sudo dnf -y install git
else
echo "Please manually install git using your distro's package manager"
exit 1
fi
fi

if [[ "$OS_ID_TYPE" = "debian" ]] || [[ "$OS_LIKE_ID_TYPE" = "debian" ]]; then
if ! command -v mutter >/dev/null 2>&1; then
sudo apt -y install mutter
fi
fi
}

install_dep(){
if [[ "$OS_ID_TYPE" = "debian" ]] || [[ "$OS_LIKE_ID_TYPE" = "debian" ]]; then
sudo apt -y install libglib2.0-dev build-essential libmutter-$DIFF_VALUE_2-dev gobject-introspection meson
elif [[ "$OS_ID_TYPE" = "fedora" ]] || [[ "$OS_LIKE_ID_TYPE" = "fedora" ]]; then
sudo dnf -y install glib2-devel @c-development meson mutter-devel gobject-introspection
else
echo "Please manually install the equivalent build dependencies on your computer"
sleep 5
fi
}

install_lib(){
prep_stage
meson setup build
meson compile -C build
meson install -C build --destdir "$dest_dir"
sudo cp -rf ./build/binary/usr/local/* /usr/
echo "For the changes to apply, please log out and then log back in."
}

uninstall_lib(){
check_env
if [[ "$OS_ID_TYPE" = "debian" ]] || [[ "$OS_LIKE_ID_TYPE" = "debian" ]] || [[ "$OS_ID_TYPE" = "fedora" ]] || [[ "$OS_LIKE_ID_TYPE" = "fedora" ]]; then
sudo rm -rf /usr/include/blur-effect-1.0
if [ -e /usr/lib64/libblur-effect-1.0.so ]; then
sudo rm /usr/lib64/girepository-1.0/Blur-1.0.typelib /usr/lib64/pkgconfig/blur-effect-1.0.pc /usr/lib64/libblur-effect-1.0.so /usr/lib64/libblur-effect-1.0.so.1 /usr/lib64/libblur-effect-1.0.so.1.0.0 /usr/share/gir-1.0/Blur-1.0.gir || true
elif [ -e /usr/lib/x86_64-linux-gnu/libblur-effect-1.0.so ]; then
sudo rm /usr/lib/x86_64-linux-gnu/girepository-1.0/Blur-1.0.typelib /usr/lib/x86_64-linux-gnu/pkgconfig/blur-effect-1.0.pc /usr/lib/x86_64-linux-gnu/libblur-effect-1.0.so /usr/lib/x86_64-linux-gnu/libblur-effect-1.0.so.1 /usr/lib/x86_64-linux-gnu/libblur-effect-1.0.so.1.0.0 /usr/share/gir-1.0/Blur-1.0.gir || true
elif [ -e /usr/lib/libblur-effect-1.0.so ]; then
sudo rm /usr/lib/girepository-1.0/Blur-1.0.typelib /usr/lib/pkgconfig/blur-effect-1.0.pc /usr/lib/libblur-effect-1.0.so /usr/lib/libblur-effect-1.0.so.1 /usr/lib/libblur-effect-1.0.so.1.0.0 /usr/share/gir-1.0/Blur-1.0.gir || true
fi
echo "For the changes to apply, please log out and then log back in."
fi
}

prep_stage(){
REPO="https://github.com/kancko/gnome-rounded-blur"
dest_dir="./binary"
build_dir="/tmp"
check_env
install_git
cd "$build_dir"
rm -rf gnome-rounded-blur
git clone "$REPO"
cd gnome-rounded-blur
MUTTER_SYS_VER=$(mutter --version | grep -o -P '(?<=mutter ).*' | sed -e 's/"//g' -e "s/'//g" -e 's/\..*//g')
HARDCODE_MUTTER_SYS_VER=$(grep -o -P '(?<=mutter_req = ).*' meson.build | sed -e 's/"//g' -e "s/'//g" -e 's/\..*//g' -e 's/>//g' -e 's/=//g' -e 's/ //g')
MUTTER_API_REPO_VER=$(grep -o -P '(?<=mutter_api_version = ).*' meson.build | sed -e 's/"//g' -e "s/'//g" -e 's/ //g')
if [[ "$MUTTER_SYS_VER" -ge "$HARDCODE_MUTTER_SYS_VER" ]]; then
DIFF_VALUE=$(echo "$MUTTER_SYS_VER - $HARDCODE_MUTTER_SYS_VER" | bc)
DIFF_VALUE_2=$(echo "$MUTTER_API_REPO_VER + $DIFF_VALUE" | bc)
sed -i -e '0,/mutter_api_version = '"$MUTTER_API_REPO_VER"'/{s/'"$MUTTER_API_REPO_VER"'/'"$DIFF_VALUE_2"'/g}' meson.build
else
DIFF_VALUE=$(echo "$HARDCODE_MUTTER_SYS_VER - $MUTTER_SYS_VER" | bc)
DIFF_VALUE_2=$(echo "$MUTTER_API_REPO_VER - $DIFF_VALUE" | bc)
sed -i -e '0,/mutter_req = '"$HARDCODE_MUTTER_SYS_VER"'/{s/'"$HARDCODE_MUTTER_SYS_VER"'/'"$MUTTER_SYS_VER"'/g}' meson.build
sed -i -e '0,/mutter_api_version = '"$MUTTER_API_REPO_VER"'/{s/'"$MUTTER_API_REPO_VER"'/'"$DIFF_VALUE_2"'/g}' meson.build
fi
install_dep
}

help_doc(){
echo "-i install the library"
echo "-u uninstall the library"
echo "-h help"
}

set -o errexit -o pipefail -o noclobber -o nounset
getopt --test > /dev/null && true
if [[ $? -ne 4 ]]; then
echo 'I’m sorry, `getopt --test` failed in this environment.'
exit 1
fi
LONGOPTS=install,uninstall,help
OPTIONS=iuh
PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@") || exit 2
eval set -- "$PARSED"
i=n u=n h=n
while true; do
case "$1" in
-i|--install)
i=y
install_lib
shift
break
;;
-u|--uninstall)
u=y
uninstall_lib
shift
break
;;
-h|--help)
h=y
help_doc
shift
break
;;
--)
shift
break
;;
*)
echo "Programming error"
exit 3
;;
esac
done
