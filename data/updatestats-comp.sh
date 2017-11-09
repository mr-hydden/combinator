#!/bin/bash

#*****************************************************************************#
#                               updatestats.sh                                #
#                                                                             #
# Incorpora una nueva entrada con los datos de una partida al fichero de      #
# estadisticas.                                                               #
#                                                                             #
#*****************************************************************************#

# Author: Samuel Gomez Sanchez
# Date: 08/11/17
# v3.0

# Usage:
#   updatestats.sh STATS_FILE A B C D E F G
#
# donde:
#   A = PID del proceso del juego (Numero entero)
#   B = Fecha de la partida (Cadena de texto)
#   C = Hora de la partida (Cadena de texto)
#   D = Numero de intentos en la partida (Numero entero)
#   E = Duracion de la partida en segundos (Numero entero)
#   F = Longitud de la combinacion (Numero entero)
#   G = Combinacion secreta del juego
#
# (en realidad la unica LIMITACION es el NUMERO DE LOS ARGUMENTOS. Internamente
# trabaja  con  cadenas  de  texto, y las escribe en cualquier caso en el orden 
# en que se reciban).
#
    # Exit status
    #
    #   0 si tiene exito
    #
    #   1 si los argumentos son erroneos
    #
    #   2 si hay algun problema con el fichero



# Constantes

N_FIELDS=7

STATS_FILE_PATH_GLOBAL=$PWD
STATS_FILE_GLOBAL='estadisticas.txt'

declare -i N_PERM=2#000    # ---
declare -i R_PERM=2#100    # r--
declare -i W_PERM=2#010    # -w-
declare -i X_PERM=2#001    # --x
declare -i RW_PERM=2#110   # rw-
declare -i WX_PERM=2#011   # -wx
declare -i RX_PERM=2#101   # r-x
declare -i RWX_PERM=2#111  # rwx






#*****************************************************************************#
#                                   FUNCIONES                                 #
#*****************************************************************************#
#                                   perm                                      #
#                                   init_stats_file                           #
#*****************************************************************************#


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

        # Si no existe el fichero, devolvemos error
        if ! [[ -e "$FILE" ]]; then
            echo 8 # 2#1000, valor invalido; fichero no existe
            return 2
        fi

        # Calculamos los permisos sumando el valor de cada variable de permisos
        if [ -r "$FILE" ]; then
            (( PERMISSIONS += $R_PERM )) # Incluimos permiso r--
        fi
        if [ -w "$FILE" ]; then
            (( PERMISSIONS += $W_PERM )) # Incluimos permiso -w-
        fi
        if [ -x "$FILE" ]; then
            (( PERMISSIONS += $X_PERM )) # Incluimos permiso --x
        fi

        echo $PERMISSIONS # Devolvemos con echo para shell substitution
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
    
    local STATS_FILE=$1
    local STATS_FILE_PATH
    local STATS_FILE_NAME

    if [ $# -eq 1 ]; then

        # Separamos directorio padre y fichero para trabajar por separado
        STATS_FILE_PATH=$(echo $STATS_FILE | sed -n 's:\(.*\)/.*$:\1:p')
        STATS_FILE_NAME=$(echo $STATS_FILE | sed -n 's:.*/\(.*\)$:\1:p')

        # Si sed no separa adecuadamente, toma $1 como un nombre de fichero y
        # lo crea en el directorio $STATS_FILE_PATH_GLOBAL
        if [[ -z "$STATS_FILE_NAME" || -z "$STATS_FILE_PATH" ]];then
            STATS_FILE_NAME=$STATS_FILE
            STATS_FILE_PATH=$STATS_FILE_PATH_GLOBAL
        fi

        # Si el directorio no existe, lo creamos, con todos los intermedios
        if ! [[ -e "$STATS_FILE_PATH" ]]; then
            mkdir -p "$STATS_FILE_PATH" &> /dev/null
            if (( $? != 0 )); then  # Si el directorio no se creo correctamente
                return 2            # (porque no hay permisos, por ejemplo)
            fi
        fi
        
        # Comprobamos que podemos trabajar en el directorio que contiene
        # el fichero de configuracion
        declare -i local DIR_PERM=$(perm "$STATS_FILE_PATH") 
        if (( $DIR_PERM == $RWX_PERM )); then

            cd "$STATS_FILE_PATH"

            if ! [[ -e "$STATS_FILE_NAME" ]]; then
                touch "$STATS_FILE_NAME"   # Como tenemos permisos W, 
                                           # se crea sin problema
            fi
                
            # El modulo superior debe realizar la comprobacion 
            # de que se puede escribir en el fichero iniciado, 
            # ya que no conocemos el umask del sistema
            #
            #if ! (( (( $FIL_PERM & $W_PERM )) != 0 )); then
            #    return 3 # No podemos escribir en el fichero
            #else
            #    return 0
            #fi

        else
            return 3 # No hay permisos en el directorio
        fi
    else
        return 1 # Argumentos erroneos en numero
    fi

}


#*****************************************************************************#
#                               PROGRAMA PRINCIPAL                            #
#                                 updatestats.sh                              #
#*****************************************************************************#

    # Exit status
    #
    #   0 si tiene exito
    #
    #   1 si los argumentos son erroneos
    #
    #   2 si hay algun problema con el fichero

# Debe haber 8 argumentos obligatoriamente
if [ $# -eq 8 ]; then

# Recogemos los argumentos en variables de nombre mas legible
    STATS_FILE=$1
    GAME_PID=$2
    GAME_DATE=$3
    GAME_TIME=$4
    NO_ATTEMPTS=$5
    GAME_DURATION=$6
    COMB_LENGTH=$7
    COMBINATION=$8

    # '.' no es un wildcard para el globbing, asi que
    # cambiamos '.' por $PWD, pues necesitamos rutas absolutas
    STATS_FILE=$(echo $STATS_FILE | sed "s:\./\(.*\):$PWD/\1:")

    if ! [[ $STATS_FILE =~ .*"$STATS_FILE_GLOBAL" ]]; then
        exit 2 # El fichero debe llamarse $STATS_FILE_GLOBAL
    fi

    # Si el fichero no existe, lo creamos
    if ! [[ -e $STATS_FILE ]]; then
        init_stats_file $STATS_FILE
        if (( $? != 0 )); then
            exit 2 # Error con el fichero
        fi
    fi

    # Comprobamos permisos del fichero; si no se puede escribir, 
    # termina con error
    declare -i FIL_PERM=$(perm "$STATS_FILE") 
    if ! (( (( $FIL_PERM & $W_PERM )) != 0 )); then
        exit 2 # No podemos escribir en el fichero
    else
        echo "$GAME_PID|$GAME_DATE|$GAME_TIME|$NO_ATTEMPTS|$GAME_DURATION|\
$COMB_LENGTH|$COMBINATION" | cat >> "$STATS_FILE"
        exit 0
    fi
    
else
    exit 1; # Error en el formato de los argumentos
fi
