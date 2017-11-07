#!/bin/bash

# Script de para el menu de configuracion
# 
# Usage: conf_if.sh GLOBAL_ARRAY
#
# El script muestra un menu y obtiene la informacion necesaria para realizar
# los cambios solicitados por el usuario; los devuelve en un 




# CONSTANTES
MIN_LEN=2
MAX_LEN=6
STATS_FILE_GLOBAL='estadisticas.txt'

# VARIABLES
RETURN_ARRAY=$1

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

            break
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

            # Llevamos a cabo el cambio de fichero de estadisticas
#            "$(dirname $PWD)/$CHCONF" "$(dirname $PWD)/$CONFIG_FILE_GLOBAL" \
#            -s "$STATFILE"

            break
        ;;
    
        c)
            RETURN_ARRAY[0]=$LENGTH
            RETURN_ARRAY[1]=$STATFILE
        ;;
    esac
done

exit 0
