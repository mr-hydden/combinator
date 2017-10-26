#!/bin/bash

CONFIG_FILE='conf.cfg'
STATS_FILE='estadisticas.txt'
CONFIG_FILE_STATS_FORMAT_REGEX='ESTADISTICAS=.*estadisticas.txt$'
CONFIG_FILE_STATS_MODIFIED_FORMAT=
#Uncomment to use replacement for #ZZZ
STATS_LINE=2


if [ $# -ge 1 -a $# -le 2 ]; then
# La comprobacion de los limites del numero queda para el modulo superior
# Este coge cualquier cadena numerica de cualquier longitud entre 1 y 9
# Asi seria facilmente modificable si se quiere extender el programa
    if [[ $1 =~ [1-9] ]]; then

        NEW_LENGTH=$1

        if [ $# -eq 2 ]; then
            if [[ $2 =~ .*"$STATS_FILE" ]]; then
                
                NEW_PATH=$2
                if ! [ -w "$PWD" ]; then
                # Faltan permisos en carpeta actual
                    exit 3
                fi

                if ! [ -e "$PWD/$CONFIG_FILE" ]; then
                # Si no existe, creamos el fichero
                    touch "$CONFIG_FILE"
                fi
                
                if ! [ -w "$PWD/$CONFIG_FILE" ]; then
                # Faltan permisos para el fichero
                    exit 4
                fi

                echo "LONGITUD=$NEW_LENGTH" > "$PWD/$CONFIG_FILE"
                echo "ESTADISTICAS=$NEW_PATH" >> "$PWD/$CONFIG_FILE"
             
            else
            #Formato argumentos no adecuado
                exit 1 
            fi            


        else

            if ! [ -w "$PWD" ]; then
            # Faltan permisos en carpeta actual
                exit 3
            fi

            if ! [ -e "$PWD/$CONFIG_FILE" ]; then
            # Si no existe, creamos el fichero
                touch "$CONFIG_FILE"
            fi
            
            if ! [ -w "$PWD/$CONFIG_FILE" ]; then
            # Faltan permisos para el fichero
                exit 4
            fi
            
            #ZZZ
            #STATS_PATH=$(cat "$PWD/$CONFIG_FILE" | \
            #            grep "$CONF_FILE_STATS_FORMAT_REGEX")

            #CONFIG_FILE_STATS_MODIFIED_FORMAT=\
            #${CONFIG_FILE_STATS_MODIFIED_FORMAT/ESTADISTICAS=.*/\
            #ESTADISTICAS="$S2"}
            
            #STATS_PATH=${STATS_PATH/CONFIG_FILE_STATS_FORMAT_REGEX/\
            #CONFIG_FILE_STATS_MODIFIED_FORMAT}

            #echo "LONGITUD=$NEW_LENGTH" > "$PWD/$CONFIG_FILE"
            #echo "$STATS_PATH" >> "$PWD/$CONFIG_FILE"

            # This should work as well as a replacement from #ZZZ
             sed -i "$STATS_LINEs/.*/replacement-line/" "$PWD/$CONFIG_FILE"
        fi

    else

#Formato argumentos no adecuado
        exit 1 

    fi    

elif [ $# -gt 2 ]; then
# Uso erroneo
    exit 2

else
# Sin argumentos, se considera que no se desean cambios
    exit 0
fi
