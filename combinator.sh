#!/bin/bash


#***********VARIABLES**************

RELEASE_DATE=$(date +'%b-%Y')
VERSION='v1.0'
declare -a COMBINATION
declare -a SECRET_KEY
declare -a USER_KEY
declare -a ACIERTOS
long=3       #Longitud provisional
MIN_LENGTH=2
MAX_LENGTH=6

export NEW_LENGTH=      # Es esto o crear un fichero temporal. Porque si
export NEW_STATS_FILE=  # conf_if se ejecuta en una subshell, no podemos
                        # recoger lo que  devuelve,  pues tiene interfaz


#echo
#echo
#echo
#echo
#echo
#echo
#echo
#echo '                            Combinator'
#echo '                      '"$VERSION"'              '"$RELEASE_DATE"
#echo
#echo
#echo
#echo
#echo '    Copyright Samuel Gómez Sánchez, Luis Blázquez Miñambres,'\
#     $(date +'%Y')
#echo '                       All Rights Reserved.'
#echo
#echo
#echo
#echo

MENU_TITLE='****************************************'
MENU_TITLE+='***************************************'
MENU_TITLE+='                                        '
MENU_TITLE+='                                       '
MENU_TITLE+='                                   '
MENU_TITLE+='COMBINATOR'
MENU_TITLE+='                                   '
MENU_TITLE+='****************************************'
MENU_TITLE+='***************************************'

#MENU
END=0
while (( $END == 0)); do
    
    clear    

    echo -n '***********************************'
    echo '***********************************'
    echo -n '*                             '
    echo -n 'COMBINATOR'
    echo '                             *'
    echo -n '***********************************'
    echo '***********************************'
    echo
    echo

    echo '    J) JUGAR'
    echo '    C) CONFIGURACION'
    echo '    E) ESTADISITICAS'
    echo '    G) GRUPO'
    echo '    S) SALIR'
    read -p '    La Caja Fuerte. Introduzca una opcion >>' OPCION

    case "$OPCION" in
        'J' | 'j')
            "$PWD/view/game_if.sh"       
        ;;

        'C' | 'c')
            source "$PWD/view/conf_if.sh"
            echo $NEW_LENGTH $NEW_STATS_FILE
            sleep 20
        ;;

        'E' | 'e')
            "$PWD/view/statistics_if.sh"
        ;;

        'G' | 'g')
            "$PWD/view/group_if.sh"
        ;;

        'S' | 's')
            echo 'Saliendo...'
            sleep 1
            END=1
        ;;

        *)
            echo 'OPCION INCORRECTA . Intentelo de nuevo'
            echo Reconectando...
            sleep 5
        ;;

    esac   
done

unset NEW_LENGTH
unset NEW_STATS_FILE

exit 0
