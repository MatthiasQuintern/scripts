#!/bin/bash
# skript um in ordnern alle inhalte rekursiv mit gpg zu verschlüsseln

shopt -s nullglob

encrypt_folder() {

    # echo "Verschlüssele Dateien in $PWD"
    echo "Dateien in $PWD werden nach ${PWD/$origin_base/$origin_base"_encrypted"} verschlüsselt..."

    # Verschlüssele alle Dateien 
    ls -Ap | grep -v / | gpg --encrypt-files --recipient "matthiasqui2000@gmail.com" &&
    
    mv *.gpg "${PWD/$origin_base/$origin_base"_encrypted"}/"

    # echo "Dateien in $PWD wurden nach ${PWD/$origin_base/$origin_base"_encrypted"} verschlüsselt"
    
    # rekursiver aufruf für alle ordner
    find . -maxdepth 1 -mindepth 1 -type d | while read dir; 
    do
        # Erstellt das Verzeichnis im "encrypted" Ordner
        mkdir "${PWD/$origin_base/$origin_base"_encrypted"}/$dir"
       
        # echo "Betrete Ordner: $dir" 
        cd "$dir"
        # echo "Aktueller Pfad: $PWD"
        encrypt_folder
        cd ..
    done
    
}

decrypt_folder() {

    echo "Entschlüssle Dateien in $PWD"
    ls -A | grep .gpg | gpg --decrypt-files &&

    [ $keep_enc == "j" ] && rm *.gpg

    # echo "Dateien in $PWD wurden entschlüsselt"

    for dir in $(ls -Ap | grep /)
    do
        # Ruft decrypt in allen Unterverzeichnissen auf
        cd "$dir"
        decrypt_folder
        cd ..
    done

}

origin_dir=$PWD

operation=$(printf "Verschlüsseln\nEntschlüsseln" | dmenu -l 2 -p "Operation auf $PWD wählen:")

# kopiert das zielverzeichnis nach ../$zielverzeichnis_en/decrypted und wechselt dort hin, started dann die en/decrypt function
case $operation in

    "Verschlüsseln")
        echo "Beginne Verschlüsseln von $PWD"
        
        origin_base=$(basename $origin_dir)
        
        mkdir $PWD"_encrypted"

        # crypt_dir=$PWD"_encrypted"
        # cp -Lr $origin_dir $crypt_dir &&
        # cd $crypt_dir || echo "Fehler beim kopieren" 
        
        encrypt_folder
        ;;

    "Entschlüsseln")
        
        read -p "Verschlüsselte Dateien löschen? (j/n): " keep_enc
        
        echo "Beginne Entschlüsseln von $PWD"

        # crypt_dir=$PWD"_decrypted"
        # cp -Lr $origin_dir $crypt_dir && 
        # cd $crypt_dir || echo "Fehler beim kopieren" 

        decrypt_folder
        ;;
esac
