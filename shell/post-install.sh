#!/bin/bash
# Made by Matthias Quintern
# This software comes with no warranty.

# Get the dir to cd back to it when leaving
CONFIG_DIR=$PWD

#
# SETTINGS
#
# Path to the config sync script
CONFIG_SYNC="$HOME/.scripts/config-sync.sh --update"
WINE_DIR=$HOME/.wine

# packages to install
declare -a pkgs_init=(wget git rsync python-pip fakeroot binutils make patch gcc)
declare -a pkgs_terminal=(ffmpeg zip unzip tar ntfs-3g neofetch gdb youtube-dl)
declare -a pkgs_ranger=(ranger)
declare -a pkgs_zsh=(zsh zsh-syntax-highlighting)
declare -a pkgs_vim=(gvim nodejs npm clang doxygen texlive-core texlive-latexextra)
declare -a pkgs_x=(xorg-server xorg-apps)
declare -a pkgs_lxdm=(lxdm)
declare -a pkgs_lxdm_aur=(lxdm-themes)
declare -a pkgs_bspwm=(bspwm sxhkd picom python-pywal rofi playerctl python-dbus ttf-ubuntu-font-familiy ttf-nerd-fonts-symbols nitrogen)
declare -a pkgs_bspwm_aur=(polybar ttf-unifont)
declare -a pkgs_xfce=(xfce4 thunar-media-tags-plugin xfce4-mount-plugin xfce4-notifyd xfce4-pulseaudio-plugin xfce4-screensaver xfce4-taskmanager xfce4-whiskermenu-plugin)
declare -a pkgs_graphical_core=(android-file-transfer xfce4-terminal ueberzug flameshot firefox libreoffice-fresh libreoffice-fresh-de zathura zathura-pdf-poppler sxiv pavucontrol catfish ttf-ubuntu-font-family)
declare -a pkgs_graphical_media=(gimp strawberry vlc audacity)
declare -a pkgs_graphical_gaming=(steam discord) 

declare -a pkgs_tum_vpn=(networkmanager openvpn networkmanager-openvpn)
declare -a pkgs_tum_vpn_pip=(eduvpn-client)
declare -a pkgs_wine=(wine wine-gecko wine-mono wineasio winetricks)
declare -a pkgs_jack=(jack2 jack2-dbus qjackctl pulseaudio-jack)

# 
# UTILITY
#
INIT=0
# indent shows tree
CORE=0
    TERMINAL_PROGRAMS=0
        ZSH=0
        VIM=0
    X=0
    BSPWM=0
    XFCE=0
    GRAPHICAL_PROGRAMS=0
TUM_VPN=0
WINE=0
JACK=0

show_help()
{
    printf "\e[34mFlags:\e[33m
    Argument        Short   Install:\e[0m
    --init          -i      pacman.conf, sudo, pam_env
    --core          -c      --terminal --X --BSPWM --XFCE --graphical
    --zsh                   zsh shell
    --X --x         -x      Xorg, LXDM
    --bspwm         -b      BSPWM with polybar, sxhkd, pywal, nitrogen, picom
    --xfce                  xfce4 desktop environment, thunar & some other xfce4 programs      
    --terminal      -t      command line programs, including --zsh --vim 
    --graphical     -g      gui programs
    --eduvpn                eduvpn
    --wine          -w      wine, wineasio, winetricks, create default wineprefix
    --jack          -j      jack2, qjackctl\n"
}

FMT_MESSAGE="\e[1;34m%s\e[0m\n"
FMT_ERROR="\e[1;31mERROR: \e[0m%s\n"
# bold green
FMT_INSTALL="\e[1;32mInstalling: \e[0m"
# blue with normal ,
FMT_PKGS="\e[36m%s\e[0m, "
print_pkgs()
{
    printf "$FMT_INSTALL"
    printf "$FMT_PKGS" "${@}" | sed "s/, \$/\n/"
}

#
# PARSE ARGS
#
if [ -z $1 ]; then
    show_help
    exit 0
fi
while (( "$#" )); do
    case "$1" in
        -i|--init)
            INIT=1
            shift
            ;;
        -c|--core)
            CORE=1
            shift
            ;;
        --zsh)
            ZSH=1
            shift
            ;;
        --X|--x)
            X=1
            shift
            ;;
        --bspwm)
            BSPWM=1
            shift
            ;;
        --xfce)
            XFCE=1
            shift
            ;;
        -t|--terminal)
            TERMINAL_PROGRAMS=1
            shift
            ;;
        -g|--graphical)
            GRAPHICAL_PROGRAMS=1
            shift
            ;;
        --eduvpn)
            TUM_VPN=1
            shift
            ;;
        --wine)
            WINE=1
            shift
            ;;
        --jack)
            JACK=1
            shift
            ;;
        *) # unsupported flags
            printf "$FMT_ERROR" "Unsupported argument or flag $1" >&2
            show_help
            exit 1
            ;;
    esac
done


#
# INIT: pacman conf, sudo and pam_env (for XDG_..._HOME variables)
#
if [ $INIT = 1 ]; then
    # if not running as root
    if [ ! $(whoami) -e "root" ]; then
        printf "$FMT_ERROR" "Initialisation needs to be run as root."
        exit 1
    fi

    # sudoers not in dir
    if [ -z $(ls | grep "etc") ]; then
        printf "$FMT_ERROR" '"etc" directory not found. Navigate to folder containing dotfiles and re-run.'
        exit 1
    fi

    printf "\e[1;34m%s\e[0m" "The following files will be installed from $PWD/etc WITHOUT backing up the files already in the system: ";
    printf "\e[1m%s, %s, %s\e[0m\n"  "pacman.conf" "pam_env.conf" "sudoers"
    printf "\e[1;34m%s\e[0m" "The following programs will be installed: "
    printf "\e[1m%s \e[0m" "${pkgs_init[@]}"; echo

    read -p "Continue? [y/n]: " answer
    case $answer in
        y|Y)
            ;;
        *)
            printf "$FMT_MESSAGE" "Cancelled."
            exit 0
            ;;
    esac

    printf "$FMT_MESSAGE" "Installing pacman.conf"
    cp etc/pacman.conf /etc/

    printf "$FMT_MESSAGE" "Installing pam_env"
    cp etc/security/pam_env.conf /etc/security/

    printf "$FMT_MESSAGE" "Updating pacman mirrors"
    pacman -Sy

    printf "$FMT_MESSAGE" "Installing archlinux-keyring"
    pacman -S archlinux-keyring

    printf "$FMT_MESSAGE" "Updating pacman keys. This might take a while."
    pacman-key --refresh-keys

    printf "FMT_INSTALL" "${pkgs_init[@]}"
    pacman -S "${pkgs_init[@]}"
    # cant use $CONFIG_SYNC since rsync is not installed yet
    printf "$FMT_MESSAGE" "Installing sudoers config"
    cp etc/sudoers /etc

    printf "$FMT_MESSAGE" "Please log out and log in as user, then run \"echo \$XGD_CONFIG_HOME\". It should not be empty"
    exit 0
fi


# allow script to only be run as user
# the scripts uses "~" and I dont want the stuff to end up in /root
# also, you shouldnt run yay as root
if [ $(whoami) = "root" ]; then
    printf "$FMT_ERROR" "This script uses sudo if it needs root-rights. Please run it as user. (Except when using -i)"
    exit 1
fi


printf "$FMT_MESSAGE" "Updating pacman mirrors"
sudo pacman -Sy

# INSTALL TERMINAL PROGRAMS
if [ $TERMINAL_PROGRAMS = 1 ] || [ $CORE = 1 ]; then
    print_pkgs ${pkgs_terminal[@]}
    sudo pacman -S ${pkgs_terminal[@]}

    print_pkgs "yay"
    cd /tmp
    git clone https://aur.archlinux.org/yay-git.git
    cd yay-git
    makepkg -si
    cd $CONFIG_DIR

    # RANGER
    print_pkgs ${pkgs_ranger[@]}
    sudo pacman -S ${pkgs_ranger[@]}
    $CONFIG_SYNC ranger

    # NICOLE
    print_pkgs "nicole"
    cd /tmp
    git clone "https://github.com/MatthiasQuintern/nicole"
    cd nicole
    sudo pip3 install .

    cd $CONFIG_DIR
fi


# INSTALL ZSH
if [ $ZSH = 1 ] || [ $TERMINAL_PROGRAMS = 1 ] || [ $CORE = 1 ]; then
    print_pkgs ${pkgs_zsh[@]}
    sudo pacman -S ${pkgs_zsh[@]}
    printf "$FMT_MESSAGE" "Setting zsh as default shell"
    sudo usermod -s /bin/zsh $(whoami)
    $CONFIG_SYNC zsh aliasrc
fi 


# INSTALL VIM
if [ $VIM = 1 ] || [ $TERMINAL_PROGRAMS = 1 ] || [ $CORE = 1 ]; then
    print_pkgs ${pkgs_vim[@]}
    sudo pacman -S ${pkgs_vim[@]}
    # vimrc
    $CONFIG_SYNC vim
    # plugged
    print_pkgs "vim-plugged"
    mkdir -p ~/.vim/autoload/master
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

    printf "$FMT_MESSAGE" "Installing vim plugins listed in vimrc"
    vim -c PlugInstall
    printf "$FMT_MESSAGE" "Installing coc-extensions: clangd, python"
    vim -c "CocInstall coc-clangd" -c "CocInstall coc-python"
fi


# INSTALL X and LXDM
if [ $X = 1 ] || [ $CORE = 1 ]; then
    print_pkgs ${pkgs_x[@]}
    sudo pacman -S ${pkgs_x[@]}
    # https://wiki.archlinux.org/title/Xorg
    $CONFIG_SYNC X11

    # install drivers
    driver=0
    read -p "Please select a driver:\n1) nvidia\n2) nouveau\n3) intel\n4) amd\nDriver (number): " driver
    case $driver in
        1)
            drivers="nvidia nvidia-utils lib32-nvidia-utils" ;;
        2)
            drivers="mesa lib32-mesa xf86-video-nouveau" ;;
        3)
            drivers="mesa lib32-mesa xf86-video-intel vulkan-intel" ;;
        4)
            drivers="mesa lib32-mesa xf86-video-amdgpu vulkan-radeon" ;;
        *)
            drivers="" ;;
    esac
    sudo pacman -S $drivers

    print_pkgs ${pkgs_lxdm[@]}
    sudo pacman -S ${pkgs_lxdm[@]}
    print_pkgs ${pkgs_lxdm_aur[@]}
    yay -S ${pkgs_lxdm_aur[@]}
    $CONFIG_SYNC lxdm
    printf "$FMT_MESSAGE" "Enabling lxdm"
    sudo systemctl enable lxdm
fi


# INSTALL BSPWM
if [ $BSPWM = 1 ] || [ $CORE = 1 ]; then
    print_pkgs ${pkgs_bspwm[@]}
    sudo pacman -S ${pkgs_bspwm[@]}
    print_pkgs ${pkgs_bspwm_aur[@]}
    yay -S ${pkgs_bspwm_aur[@]}
    $CONFIG_SYNC bspwm sxhkdrc picom polybar
    printf "$FMT_MESSAGE" "Launch nitrogen when X is set up to select a wallpaper"
    printf "$FMT_MESSAGE" "Run ~/.config/polybar/shapes/scripts/pywal.sh to generate a polybar color theme for the wallpaper"
fi


# INSTALL XFCE4
if [ $XFCE = 1 ] || [ $CORE = 1 ]; then
    print_pkgs ${pkgs_xfce[@]}
    sudo pacman -S ${pkgs_xfce[@]}
    $CONFIG_SYNC xfce4
fi


# INSTALL GRAPHICAL_PROGRAMS
if [ $GRAPHICAL_PROGRAMS = 1 ] || [ $CORE = 1 ]; then
    print_pkgs ${pkgs_graphical_core[@]}
    sudo pacman -S ${pkgs_graphical_core[@]}
    $CONFIG_SYNC terminal

    print_pkgs ${pkgs_graphical_media[@]}
    sudo pacman -S ${pkgs_graphical_media[@]}
    $CONFIG_SYNC strawberry gimp audacity
    print_pkgs ${pkgs_graphical_gaming[@]}
    sudo pacman -S ${pkgs_graphical_gaming[@]}
fi


# INSTALL TUM eduvpn
if [ $TUM_VPN = 1 ]; then
    print_pkgs ${pkgs_tum_vpn[@]}
    sudo pacman -S ${pkgs_tum_vpn[@]}
    sudo systemctl enable --now NetworkManager
    print_pkgs ${pkgs_tum_vpn_pip[@]}
    sudo pip3 install ${pkgs_tum_vpn_pip[@]}
    eduvpn-cli configure "Technische Universität München (TUM)"
    printf "$FMT_MESSAGE" "Run \"eduvpn-cli activate\" to activate the vpn. Then check https://dnsleaktest.com"
fi


# INSTALL WINE
if [ $WINE = 1 ]; then
    # https://wiki.cockos.com/wiki/index.php/Installing_and_configuring_WineASIO
    print_pkgs ${pkgs_wine[@]}
    sudo pacman -S ${pkgs_wine[@]}
    printf "$FMT_MESSAGE" "Creating wineprefix in $WINE_DIR"
    WINEPREFIX=$WINE_DIR winecfg
    printf "$FMT_MESSAGE" "Updating wineasio config"
    regedit wineasio.cfg
fi
    

# INSTALL JACK AUDIO
if [ $JACK = 1 ]; then
    print_pkgs ${pkgs_jack[@]}
    sudo pacman -S ${pkgs_jack[@]}
    $CONFIG_SYNC jack
fi
