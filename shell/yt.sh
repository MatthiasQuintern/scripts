#!/bin/sh
# Matthias Quintern
# 2021
# This software comes with no warranty

process_file()
{
    file=$(cat $filepath)
    for url in ${file[@]}; do
        process_url
    done
}

process_url()
{
    if [ -z "$best_mp4" ]; then
        # type
        if [ -z "$typ" ]; then
            yt-dlp -F $url && 
            read -p "Typ wählen: " typ
        fi

        # convert to mp3?
        if [ -z "$to_mp3" ]; then
            read -p "Nach mp3 konvertieren? (j/*): " to_mp3
        fi

        # get name
        if [ $ask_name ]; then
            read -p "Dateiname: " name
        else
            name=""
        fi


        # download (and convert)
        case $to_mp3 in
            j|J)
                if [ -z "$name" ]; then
                    read -p "Dateiname (ohne .mp3): " name
                    name=$name.mp3
                fi
                yt-dlp -f $typ $url -o - | ffmpeg -i  pipe:0 -acodec libmp3lame $name
                ;;
            *)
                if [ -z "$name" ]; then
                    yt-dlp -f $typ $url -o '%(uploader)s_%(title)s.%(ext)s'
                else
                    yt-dlp -f $typ $url -o $name
                fi
                ;;
        esac
    else
        yt-dlp -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio' --merge-output-format mp4 $url
    fi
}

show_help()
{
    printf "\e[34mFlags:\e[33m
Argument        Short   Install:\e[0m
--help          -h      show this
--file          -f      process file containing urls, seperated by newlines
--best          -b      best mp4 quality, with audio
--codec         -c      yt-dl codec
--mp3           -3      convert to mp3, does not work for playlists!
--name          -o      output filename

Any argument without a '-' is interpreted as url.
If you do not provide enough/any arguments, you will be prompted to enter the information.
"
}

while (( "$#" )); do
    case "$1" in
        -h|--help)
            show_help
            exit 0 ;;
        -f|--file)
            shift
            filepath="$1"
            shift ;;
        -c|--codec)
            shift
            typ="$1"
            shift ;;
        -3|--mp3)
            shift
            to_mp3=1
            shift ;;
        -o|--name)
            shift
            name="$1"
            shift ;;
        -b|--best)
            best_mp4="$1"
            shift ;;
        -*|--*=) # unsupported flags
            printf "$FMT_ERROR" "Unsupported flag $1" >&2
            exit 1 ;;
        *) # everything that does not have a - is interpreted as filepath
            URLS="$URLS $1"
            shift ;;
    esac
done

if [ -z "$filepath" ]; then
    if [ -z "$URLS" ]; then
        read -p "Url: " url
        process_url
    else
        for url in ${URLS[@]}; do
            process_url
        done
    fi
else
    process_file
fi

