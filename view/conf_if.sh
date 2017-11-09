#!/bin/bash

#******************************************************************************#
#                                   conf_if.sh                                 #
#                                                                              #
# Muestra una interfaz de configuracion y devuelve datos introducidos por el   #
# usuario.
#                                                                              #
#******************************************************************************#

# Author: Samuel Gomez Sanchez
# Date: 07/11/17
# v1.1

# Usage:
#   conf_if.sh
#
    # Exit status
    #
    #   0
    #
    
# Devuelve para recoger con shell substitution dos parametros:
#       LENGTH STATSFILE
# en ese orden. Si alguno no se va a cambiar, se devuelve vacio.




# Constantes
MIN_LEN=2
MAX_LEN=6
STATS_FILE_GLOBAL='estadisticas.txt'


clear

echo
echo
echo
echo
echo '                                                                         '
echo '                                 CONFIGURACION                           '
echo '                                                                         '
echo
echo '          Cambie la longitud de  combinacion  para  aumentar la          '
echo '          dificultad del juego. Si desea almacenar sus datos de          '
echo '          juego  en  otro  fichero  de estadisticas, introduzca          '
echo '          nueva ruta.'
echo 
echo
echo '                  Opciones                                           '
echo
echo '                      a) Cambiar longitud de combinacion             '
echo '                      b) Cambiar fichero de estadisticas             '
echo '                      c) Volver al menu principal                    '
echo
echo
echo

while :
do
    read -p '                  Seleccion: ' OPCION

    while ! [[ "$OPCION" =~ ^[aAbBcC]$ ]]; do        
        echo -en "\033[F\033[F" # Para que no se vea el \n, efecto estetico
        echo -n '                                        '
        echo -n '                                        '
        echo -n '                                        '
        echo -n '                                        '
        echo -en "\033[F\033[F"
        echo '                  Opcion incorrecta. Introduzca una opcion valida.'
        read -p '                  Seleccion: ' OPCION
    done
    
    echo -en "\033[F\033[F"
    echo -n '                                        '
    echo -n '                                        '
    echo -n '                                        '
    echo -n '                                        '
    echo -en "\033[F"

    case $OPCION in
        a )
            read -p '                  Nueva longitud: ' LENGTH

            while ! [[ "$LENGTH" =~ ^[0-9]$ && 
                       "$LENGTH" -ge "$MIN_LEN" && 
                       "$LENGTH" -le "$MAX_LEN"  ]]
            do
                echo -en "\033[F"
                echo -n '                                        '
                echo -n '                                        '
                echo -en "\033[F"
                read -p '                  Introduzca un valor entre 2 y 6: ' LENGTH
            done

# ESTO ES TAREA DEL CONTROLADOR, PERO COMPROBADO QUE FUNCIONA
            # Llevamos a cabo el cambio de longitud
#            "$(dirname $PWD)/$CHCONF" "$(dirname $PWD)/$CONFIG_FILE_GLOBAL" \
#            -l "$LENGTH"

            continue
        ;;

        b)
            read -p '                  Nuevo fichero de estadisticas: ' STATFILE

            while ! [[ "$STATFILE" =~ .*/?"$STATS_FILE_GLOBAL" ]]; do
                echo -en "\033[F\033[F\033[F"
                echo -n '                                        '
                echo -n '                                        '
                echo -n '                                        '
                echo -n '                                        '
                echo -n '                                        '
                echo -n '                                        '
                echo -en "\033[F\033[F\033[F"
                echo '          El nombre del fichero de configuracion debe ser: '
                echo "                          $STATS_FILE_GLOBAL"
                read -p '          Introduzca un fichero valido: ' STATFILE
            done

# ESTO ES TAREA DEL CONTROLADOR, PERO COMPROBADO QUE FUNCIONA
            # Llevamos a cabo el cambio de fichero de estadisticas
#            "$(dirname $PWD)/$CHCONF" "$(dirname $PWD)/$CONFIG_FILE_GLOBAL" \
#            -s "$STATFILE"

            continue
        ;;
    
        c)
            echo $LENGTH $STATSFILE
            NEW_LENGTH=$LENGTH
            NEW_STATS_FILE=$STATSFILE
            break
        ;;
    esac
done
