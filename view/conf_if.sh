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


    function clprevln(){ # Para funcionar sobre una terminal de 80 caracteres
                         # de ancho
        echo -en "\033[F"
        echo -n '                                        ' # 40 espacios
        echo '                                       '     # 39 espacios
        echo -en "\033[F"
    }


clear

echo
echo
echo '                                                                        '
echo '                                 CONFIGURACION                          '
echo '                                                                        '
echo
echo '          Cambie la longitud de  combinacion  para  aumentar la         '
echo '          dificultad del juego. Si desea almacenar sus datos de         '
echo '          juego  en  otro  fichero  de estadisticas, introduzca         '
echo '          nueva ruta.'
echo '          Puede  realizar los cambios que desee.  Solo se haran         '
echo '          efectivos una vez regrese al menu principal.                  '
echo
echo '                  Opciones                                              '
echo
echo '                      a) Cambiar longitud de combinacion                '
echo '                      b) Cambiar fichero de estadisticas                '
echo '                      c) Volver al menu principal                       '
echo
echo
echo

while :
do
    read -p '              Seleccion: ' OPTION

    while ! [[ "$OPTION" =~ ^[aAbBcC]$ ]]; do        
        clprevln; clprevln # Necesitamos otra linea
        echo '                  Opcion incorrecta. Introduzca una opcion valida.'
        read -p '              Seleccion: ' OPTION
    done

    clprevln; clprevln # Limpiamos lo escrito y nos situamos al principio
    echo

    case $OPTION in
        a )
            read -p '              Nueva longitud: ' LENGTH

            while ! [[ "$LENGTH" =~ ^[0-9]$ && 
                       "$LENGTH" -ge "$MIN_LEN" && 
                       "$LENGTH" -le "$MAX_LEN"  ]]
            do
                clprevln
                read -p '              Introduzca un valor entre 2 y 6: ' LENGTH
            done
            
            clprevln # Limpiamos lo escrito
            clprevln            
            echo -n '              Cambio almacenado. '
            echo 'Para confirmarlo, vuelva al menu principal'            

            continue
        ;;

        b)
            read -p '              Nuevo fichero de estadisticas: ' STATSFILE

            while ! [[ "$STATSFILE" =~ .*/?"$STATS_FILE_GLOBAL" ]]; do
                
                clprevln; clprevln # Necesitamos dos lineas

                echo -n "      El nombre del fichero de configuracion debe ser: "
                echo "'$STATS_FILE_GLOBAL'"
                read -p '      Introduzca un fichero valido: ' STATSFILE
            done
            
            clprevln; clprevln # Limpiamos lo escrito y nos situamos
            echo

            clprevln            
            echo -n '              Cambio almacenado. '
            echo 'Para confirmarlo, vuelva al menu principal'

            continue
        ;;
    
        c)
            NEW_LENGTH=$LENGTH
            NEW_STATS_FILE=$STATSFILE
            break
        ;;
    esac
done
