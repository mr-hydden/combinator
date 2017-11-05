#!/bin/bash

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
echo
echo
echo

while :
do
    read -p '                  Seleccion: ' OPCION

    while ! [[ "$OPCION" =~ ^[aAbB]$ ]]; do        
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
    esac
done

# AQUI FALTA ESCRIBIR EN UN FICHERO TEMPORAL LOS RESULTADOS, LINEA A LINEA
# PORQUE ES LA MANERA MAS FACIL DE PROCESARLOS. LA SOLUCION, TRAS COMPROBAR
# PERMISOS EN EL DIRECTORIO, ETC., DEBE SER
#       echo $LENGTH > nombreDelFichero
#       echo $STATFILE >> nombreDelFichero

exit 0
