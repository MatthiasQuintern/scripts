#!/bin/sh
# Made by Matthias Quintern
# This software comes with no warranty.

# Menü für alle meine Skripte im .scripts Ordner
# Wenn argumente übergeben werden
arg1="$1"
arg2="$2"
arg3="$3"

# -p adds a / do dirs, grep -v / removes the dir entries
choice=$(ls -p $HOME/.scripts | grep -v / | dmenu -l 7 -p "Skript auswählen:")

# -z wenn der string leer ist
if [ -z $choice ]; then
    echo "script-menu: Nichts ausgewählt!"
    
else
    # nicht mit cd, da die skripte dann nicht mehr das user-pwd verwenden
    choice="$HOME/.scripts/$choice"
    # echo "script-menu: run $choice" 
    # Richtiges programm zum öffnen bestimmen

    case $choice in
        *".py")
            python3 $choice $arg1 $arg2 $arg3
            ;;
        *".sh")    
            sh $choice $arg1 $arg2 $arg3
            ;;
        * )
            echo "$choice hat keinen bekannten Filetyp: Interpretiere als shellscript"
            sh $choice $arg1 $arg2 $arg3
            ;;
    esac
fi

