#!/bin/bash

declare -i N_PERM=2#000    # ---
declare -i R_PERM=2#100    # r--
declare -i W_PERM=2#010    # -w-
declare -i X_PERM=2#001    # --x
declare -i RW_PERM=2#110   # rw-
declare -i WX_PERM=2#011   # -wx
declare -i RX_PERM=2#101   # r-x
declare -i RWX_PERM=2#111  # rwx

N_FIELDS=7

# ***********************************************
# perm                                          *
# ***********************************************
# Comprueba los permisos del fichero o          *
# o directorio $1                               *
#                                               *
            function perm() {                         
# ***********************************************
    #
    # Return: 
    #   0 si tiene exito
    #   1 si no se reciben argumentos, o se recibe mas de uno
    #   2 si el fichero no existe o no se puede leer
    #
    # Si todo va bien, hace echo con el numero correspondiente a los permisos
    # del usuario actual, por ejemplo 6 significa rw- (110 en binario)
    # En caso de error, el echo es 8 (1000, valor invalido en otro caso)
    #

    if [ $# -eq 1 ]; then
    
        local FILE=$1
        local PERMISSIONS=0

        if ! [[ -e "$FILE" ]]; then
            echo 8 # 2#1000, valor invalido; fichero no existe
            return 2
        fi


        if [ -r "$FILE" ]; then
            # Los permisos hay que ponerlos negados porque indican que permisos
            (( PERMISSIONS += $R_PERM )) # Incluimos permiso r--
        fi
        if [ -w "$FILE" ]; then
            (( PERMISSIONS += $W_PERM )) # Incluimos permiso -w-
        fi
        if [ -x "$FILE" ]; then
            (( PERMISSIONS += $X_PERM )) # Incluimos permiso --x
        fi

        echo $PERMISSIONS
        return 0

    else
        echo 8 # 2#1000, valor invalido; formato de argumentos erroneo
        return 1
    fi
}


# ***********************************************
# init_stats_file()                             *
# ***********************************************
# Funcion que inicia un fichero de estadisticas *
# nuevo.                                        *
#                                               *
            function init_stats_file() {                         
# ***********************************************

    # Return:
    #   0 si tiene exito
    #
    #   1 si recibe argumentos erroneos
    #
    #   2 si no se pudo crear el fichero o directorio
    #
    #   3 si no se puede modificar el fichero
    #        

    local STATS_FILE_PATH=
    local STATS_FILE_NAME=

    if [ $# -eq 1 ]; then

        STATS_FILE_PATH=$(echo $1 | sed -n 's:\(.*\)/.*$:\1:p') # <-------------------- SI HAY TIEMPO, MODIFICAR init_conf_file PARA QUE RECIBA
        STATS_FILE_NAME=$(echo $1 | sed -n 's:.*/\(.*\)$:\1:p') # <-------------------- UN SOLO ARGUMENTO, AL IGUAL QUE ESTA

        if ! [[ -e "$STATS_FILE_PATH" ]]; then
            mkdir -p "$STATS_FILE_PATH" &> /dev/null
            if (( $? != 0 )); then  # Si el directorio no se creo correctamente
                return 2            # (porque no hay permisos, por ejemplo)
            fi
        fi
        
        declare -i local DIR_PERM=$(perm "$STATS_FILE_PATH") 
        if (( $DIR_PERM == $RWX_PERM )); then

            cd "$STATS_FILE_PATH"

            if ! [[ -e "$STATS_FILE_NAME" ]]; then
                touch "$STATS_FILE_NAME"   # Como tenemos permisos W, se crea sin
                                            # problema
            fi

            declare -i local FIL_PERM=$(perm "$STATS_FILE_NAME") 
                                                    # En principio
                                                    # no hace falta comprobar
                                                    # el valor de retorno,
                                                    # se los he proporcionado
                                                    # mas como una medida de 
                                                    # seguridad, o en caso
                                                    # de necesitar debugging
                
            if ! (( (( $FIL_PERM & $W_PERM )) != 0 )); then
                return 3 # No podemos escribir en el fichero
            else
                return 0
            fi

        else
            return 3 # No hay permisos en el directorio
        fi
    else
        return 1 # Argumentos erroneos en numero
    fi

}


# ***********************************************
# add_stats()                                   *
# ***********************************************
# Funcion que escribe los datos de una partida  *
# en el fichero de estadisticas
#                                               *
            function add_stats() {                         
# ***********************************************

    # Usage: add_stats FILE ${STATS_ARRAY[@]}
    #
    # Return values
    #   0 si tiene exito
    #
    #   1 si los argumentos son erroneos
    #
    #   2 si hay algun problema con el fichero

    if [ $# -eq 8 ]; then
    
        local STATS_FILE=$1
        local GAME_PID=$2
        local GAME_DATE=$3
        local GAME_TIME=$4
        local NO_ATTEMPTS=$5
        local GAME_DURATION=$6
        local COMB_LENGTH=$7
        local COMBINATION=$8

        if ! [[ -e $STATS_FILE ]]; then
            init_stats_file $STATS_FILE
            if (( $? != 0 )); then
                return 2
            fi
        fi

        echo    "$GAME_PID|$GAME_DATE|$GAME_TIME|$NO_ATTEMPTS|$GAME_DURATION|\
$COMB_LENGTH|$COMBINATION" | cat >> "$STATS_FILE"

    else
        return 1;
    fi
}

add_stats $@
