#!/bin/bash
# Made by Matthias Quintern
# 28.01.2021
# This software comes with no warranty.

cd "$PWD"
echo "$PWD"
ls | echo

declare -A origin
origin+=(
    [mp3]="mp3"
    [flac]="flac"
    [wav]="wav"
    [ogg]="ogg"
    [wma]="wma"
)

declare -A dest
dest+=(
    [mp3]="mp3"
    [flac]="flac"
    [wav]="wav"
)


origin_type=$(printf "%s\n" "${!origin[@]}"  | dmenu -p "Konvertieren von:") 

dest_type=$(printf "%s\n" "${!dest[@]}" | dmenu -p "Konvertieren nach:")

echo "Von $origin_type nach $dest_type"

case $dest_type in
    # codec bestimmen
    "flac")
        codec="flac"
        ;;
    "mp3")
        codec="libmp3lame"
        ;;
    "wav")
        codec="adpcm_ima_wav"
        ;;
    *)
        echo "Es konnte kein Codec bestimmt werden"
        exit 1
        ;;
esac

for file in *".$origin_type"
    do
        ffmpeg -i "$file" -acodec $codec "$(basename "${file/.$origin_type}")".$dest_type
        echo "Wurde konvertiert zu flac: $file"
    done

read -p "Sollen die alten Dateien gelöscht ('d') oder in einen neuen Ordner verschoben ('m') werden? [d/m/n]:" answer

case $answer in 
	# Löschen der alten Dateien
	[dD]*) 
	for file in *".$origin_type"
	do
		rm "$file"
		echo "Wurde gelöscht: $file"
	done
	echo "Alte Dateien wurden gelöscht. Fertig!"
	;;
	# Verschieben der alten Dateien in /old_files
	[mM]*)
	mkdir old_files
	for file in *".$origin_type"
	do
		mv "$file" old_files
		echo "Wurde nach 'old_files' verschoben: $file"
	done
	echo "Alte Dateien wurden verschoben. Fertig!"
	;;
	# Nichts tun
	* ) echo "Keine Dateien gelöscht. Fertig!"
	;;
esac
