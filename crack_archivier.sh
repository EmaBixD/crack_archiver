#!/bin/bash

# Funzione per verificare se un comando esiste
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Funzione per installare i pacchetti necessari
install_dependencies() {
    if command_exists apt-get; then
        apt-get update
        apt-get install -y unzip unrar p7zip-full
    else
        echo "Impossibile installare le dipendenze automaticamente. Per favore installa manualmente: unzip, unrar, p7zip-full."
        exit 1
    fi
}

# Verifica delle dipendenze
check_dependencies() {
    MISSING_DEPENDENCIES=()

    for CMD in unzip unrar 7z; do
        if ! command_exists "$CMD"; then
            MISSING_DEPENDENCIES+=("$CMD")
        fi
    done

    if [ ${#MISSING_DEPENDENCIES[@]} -eq 0 ]; then
        echo "Tutte le dipendenze sono soddisfatte."
    else
        echo "Le seguenti dipendenze sono mancanti: ${MISSING_DEPENDENCIES[*]}"
        read -p "Vuoi installare le dipendenze mancanti? [y/n] " response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            install_dependencies
        else
            echo "Dipendenze mancanti. Uscita dallo script."
            exit 1
        fi
    fi
}

# Funzione per tentare di aprire l'archivio con una password
try_password() {
    local PASSWORD=$1
    local EXTENSION=$2

    case "$EXTENSION" in
        zip)
            unzip -P "$PASSWORD" "$ARCHIVE" &> /dev/null
            ;;
        rar)
            unrar x -p"$PASSWORD" "$ARCHIVE" &> /dev/null
            ;;
        7z)
            7z x "$ARCHIVE" -p"$PASSWORD" &> /dev/null
            ;;
        *)
            echo "Formato di archivio non supportato: $EXTENSION"
            exit 1
            ;;
    esac

    if [ $? -eq 0 ]; then
        echo "Password trovata: $PASSWORD"
        exit 0
    fi
}

# Verifica e installa le dipendenze se necessario
check_dependencies

# Chiede all'utente di inserire il percorso/nome del file dell'archivio e della wordlist
read -p "Inserisci il percorso/nome del file dell'archivio da craccare: " ARCHIVE
read -p "Inserisci il percorso/nome del file della wordlist: " WORDLIST

# Controlla se i file esistono
if [ ! -f "$ARCHIVE" ]; then
    echo "Il file dell'archivio non esiste: $ARCHIVE"
    exit 1
fi

if [ ! -f "$WORDLIST" ]; then
    echo "Il file della wordlist non esiste: $WORDLIST"
    exit 1
fi

# Estrae l'estensione del file
EXTENSION="${ARCHIVE##*.}"

# Legge la wordlist riga per riga
while IFS= read -r PASSWORD; do
    try_password "$PASSWORD" "$EXTENSION"
done < "$WORDLIST"

echo "Nessuna password trovata nella wordlist."
