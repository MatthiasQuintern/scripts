#!bin/sh
# Made by Matthias Quintern
# Bildschirmverwaltung für x, bspwm, polybar
# This software comes with no warranty.

#
# Konstanten
#

# Bildschirm-Port-Namen und auflösung
left="HDMI-0"
right="DP-0"
# Bildschirm Auflösungen
leftres="1920x1080"
rightres="1920x1080"
# Bildschirm Positionen
leftpos="+0+0"
xleftpos="0x0"
rightpos="+1920+50"
xrightpos="1920x50"

# Desktop-Namen
main="Genau hier könnte Ihre Werbung stehen"
side="7 8 Discord Music Obs"

# Polybar bars
mainbar="primary"
sidebar="secondary"
# Polybar Launch Skript
polypath="$HOME/.config/polybar/launch_polybar.sh"
# Platz für die Bar
PADDING=25

# Wallpaper mit nitrogen, true/false
nitrogen=true

#
# Skript
#

# wenn das skript mit einem argument aufgerufen wird
action=$1

# dmenu optionen
declare -A options
options+=(
    [Lx]="Nur Links"
    [xR]="Nur Rechts"
    [LR]="Erweitern"
    [LL]="Duplizieren"
)
# wenn keine aktion gegeben ist, öffne dmenu
if [ -s $action ];
then
    action=$(printf "%s\n" "${!options[@]}" | dmenu -p "Bildschirmsetup:")
fi

# schiebe alle desktops zum temp monitor, lösche alle monitore
movedesktops() {
    # erstelle temp monitor
    bspc wm --add-monitor temp 100x100+0+0
    # schiebe desktops nach temp
    for d in $(bspc query --desktops)
    do
        bspc desktop $d --to-monitor temp
    done
    
    # lösche andere monitore
    for m in $(bspc query --monitors --names)
    do
        if [ ! $m = "temp" ];
        then
            bspc monitor $m --remove
        fi
    done
}

case $action in
    "Lx")
        echo "-> Lx"
        xrandr --output $left --mode $leftres --pos $xleftpos
        xrandr --output $right --off
        
        movedesktops
        bspc monitor temp -n $left -g $leftres$leftpos
        bspc monitor $left -d $main

        sh $polypath $left;;
    "xR")
        echo "-> xR"
        xrandr --output $right --mode $rightres --pos $xleftpos
        xrandr --output $left --off
        
        movedesktops
        bspc monitor temp -n $right -g $rightres$leftpos
        bspc monitor $right -d $main

        sh $polypath $right;;
    "LR")
        echo "-> LR"
        xrandr --output $left --mode $leftres --pos $xleftpos
        xrandr --output $right --mode $rightres --pos $xrightpos
        
        movedesktops
        bspc monitor temp -n $left -g $leftres$leftpos
        bspc monitor $left -d $main

        bspc wm --add-monitor $right $rightres$rightpos
        bspc monitor $right -d $side

        sh $polypath $left $right;;
    "LL")
        echo "-> LL"
        xrandr --output $left --mode $leftres --pos $xleftpos
        xrandr --output $right --mode $rightres --pos $xleftpos
        
        movedesktops
        bspc monitor temp -n $left -g $leftres$leftpos
        bspc monitor $left -d $main

        sh $polypath $left;;
    *)
        echo "Ungültiges Argument: Gültig ist 'Lx', 'xR', 'LR', 'LL'";;
esac

# padding erneut setzen damit die nodes nicht in die bar gehen
bspc config top_padding $PADDING

if $nitrogen;
then
    # reload the wallpaper
    nitrogen --restore
fi
echo "Bildschirmsetup gändert."

