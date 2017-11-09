#!/bin/bash

#*****************************************************************************#
#                                   genstats.sh                               #
#                                                                             #
# Genera las estidisticas requeridas, que escribe en un fichero temporal, a   #
# partir de la informacion en un fichero de estadisticas con el formato       #
# adecuado.                                                                   #
#                                                                             #
#*****************************************************************************#

# Author: Samuel Gomez Sanchez
# Date: 09/11/17
# v2.0

# Usage:
#   gestats.sh STATSFILE
#
    # Exit status:
    #
    #   0 si tiene exito
    #
    #   1 si los argumentos son incorrectos
    #
    #   2 si hay algun problema con el fichero de estadisticas o el temporal

# Constantes
#=============================================================================

LENGTH_POS=6    # Posicion del campo longitud en el formato 
                # del fichero de estadisticas

DURATION_POS=5  # Posicion del campo tiempo de juego en el formato
                # del fichero de estadisticas

TEMP_FILE="$PWD/.stats.tmp"
#ERROR_FILE="$PWD/.statserrlog.tmp" <---- Se ha dejado para debugging, aunque
#                                         tal  vez  se  podria  incluir en la
#                                         version  final. Es un fichero en el
#                                         que  se  registran  las  lineas mal
#                                         formateadas   en   el   fichero  de 
#                                         estadisticas.

#=============================================================================



# Variables
#=============================================================================
NO_GAMES=        # Numero de partidas
MEAN_LENGTH=     # Longitud media
MEAN_DURATION=   # Tiempo de juego medio
TOTAL_PLAY_TIME= # Tiempo total de juego

SHORTEST=   # Informacion de la partida mas corta
LONGEST=    # Informacion de la partida mas larga

                        # Informacion de las partidas mas cortas
SHORT_LEN_SHORT_GAME=       # Con la combinacion mas corta
LONG_LEN_SHORT_GAME=        # Con la combinacion mas larga
#=============================================================================


#******************************************************************************#
#                                   FUNCIONES                                  #
#******************************************************************************#
#                               test_line_format                               #
#******************************************************************************#


# ***********************************************
# test_stats_format                             *
# ***********************************************
# Devuelve 0 si el formato del fichero $1 es el *
# adecuado, y diferente de 0 si no lo es.       *
#                                               *
            function test_line_format() {                         
# ***********************************************
    #
    # Return:
    #   0 si tiene exito
    #
    #   1 si los argumentos son incorrectos
    #
    #   2 si la linea no tiene el formato adecuado

# Formato de cada linea del fichero de estadisticas
    local DATA_FORMAT='^[0-9][0-9]*|.*|.*|[0-9][0-9]*|[0-9][0-9]*|\
[0-9][0-9]*|[0-9][0-9]*$'

# Si una linea no tiene ese formato, esta mal
    if [[ $# == 1 ]]; then
        echo $1 | grep $DATA_FORMAT &> /dev/null
        if (( $? == 0 )); then
            return 0 # Linea correcta
        else
            return 2 # Linea incorrecta
        fi
    else
        return 1 # Argumentos incorrectos
    fi
}


#*****************************************************************************#
#                               PROGRAMA PRINCIPAL                            #
#                                   genstats.sh                               #
#*****************************************************************************#

    # Exit status:
    #
    #   0 si tiene exito
    #
    #   1 si los argumentos son incorrectos
    #
    #   2 si hay algun problema con el fichero de estadisticas o el temporal

if (( $# == 1)); then

    # Fichero de estadisticas
    STATS_FILE=$1
    if ! [[ -e $STATS_FILE ]]; then
        exit 2 # Si el fichero de estadisticas no existe, no hace nada
               # y devuelve error
    fi 

    # Calculamos con el numero de juego (coincidente con el numero de lineas)
    NO_GAMES=$(cat $STATS_FILE | wc -l)


    # Inicializamos
    MEAN_LENGTH=0
    MEAN_DURATION=0
    TOTAL_PLAY_TIME=0

    # Seria facil asignar la primera linea, pero si el formato es incorrecto
    # no nos interesa
    FORMAT_OK=
    LINE=1
    until (($FORMAT_OK == 0)); do
        test_line_format $(cat $STATS_FILE | head -"$LINE" | tail -1)
        if (( $? != 0)); then
            FORMAT_OK=1
            LINE=$(($LINE+1))
        else
            FORMAT_OK=0
        fi
    done
        
    MIN_DURATION=$( cat $STATS_FILE | head -"$LINE" | cut -f $DURATION_POS -d "|" )
    MAX_DURATION=$( cat $STATS_FILE | head -"$LINE" | cut -f $DURATION_POS -d "|" )
    MIN_LENGTH=$( cat $STATS_FILE | head -"$LINE" | cut -f $LENGTH_POS -d "|" )
    MAX_LENGTH=$( cat $STATS_FILE | head -"$LINE" | cut -f $LENGTH_POS -d "|" )

    MIN_LENGTH_I=$LINE   # Linea que contiene partida mas larga, corta, etc.
    MAX_LENGTH_I=$LINE   #
    MIN_DURATION_I=$LINE #
    MAX_DURATION_I=$LINE #

    SHORT_L_GAME_I=$LINE    # Linea correspondiente a las partidas mas cortas
    LONG_L_GAME_I=$LINE     # con la combinacion mas corta y mas larga

    SHORT_L_GAME_DURATION=$MIN_DURATION # Duracion de las partidas mas cortas
    LONG_L_GAME_DURATION=$MIN_DURATION  # con  la   combinacion   mas   corta 
                                        # y mas larga, respectivamente

    #if ! [[ -e "$ERROR_FILE" ]]; then <-------------- Ver nota bucle abajo 
    #    touch "$ERROR_FILE"
    #    if (( $? != 0)); then
    #        exit 2
    #    fi
    #fi


    # Recorremos linea a linea, haciendo:
        # Sumar longitudes, para calcular media
        # Sumar tiempos de juego, para calcular medio y total
        # Buscar tiempos maximo y minimo, y guardar el numero de linea
        # Buscar longitud maxima y minima, para luego buscar
            # partidas mas cortas para ambas
    I=1
    while (( $I <= $NO_GAMES )); do

        # Si el formato de una linea no es adecuado, la saltamos
        LINE=$( cat $STATS_FILE | head -"$I" | tail -1 )
        test_line_format "$LINE"
        if (( $? != 0 )); then
            I=$(($I+1))
            NO_GAMES=$(($NO_GAMES-1))
        #echo $LINE | cat >> $ERROR_FILE <---- Esto se podria incluir en la
        #                                      version   final,  o  dejarlo
        #                                      como lo tengo para debugging                                 
            continue
        fi

        # Tomamos la longitud de combinacion de esa linea, y la duracion
        # de la partida en cuestion,  para calcular lo indicado sobre el
        # bucle
        LINE_LENGTH=$(cat $STATS_FILE |\
                      head -"$I" |\
                      tail -1 |\
                      cut -f $LENGTH_POS -d "|")

        LINE_DURATION=$(cat $STATS_FILE |\
                        head -"$I" |\
                        tail -1 |\
                        cut -f $DURATION_POS -d "|")

        # Se suman longitudes y tiempos
        ((MEAN_LENGTH += $LINE_LENGTH))
        ((TOTAL_PLAY_TIME += $LINE_DURATION))

        # Si el tiempo o la longitud actual es mayor o menor que la maxima
        # y la minima, respectivamente, se van actualizando estas
        if (( $LINE_DURATION < $MIN_DURATION)); then
            MIN_DURATION=$LINE_DURATION
            MIN_DURATION_I=$I
        fi
        if (( $LINE_DURATION > $MAX_DURATION)); then
            MAX_DURATION=$LINE_DURATION
            MAX_DURATION_I=$I
        fi
        if (( $LINE_LENGTH < $MIN_LENGTH)); then
            MIN_LENGTH=$LINE_LENGTH
            MIN_LENGTH_I=$I
        fi
        if (( $LINE_LENGTH > $MAX_LENGTH)); then
            MAX_LENGTH=$LINE_LENGTH
            MAX_LENGTH_I=$I
        fi

        I=$(($I+1))

    done

    # Se calculan, ahora que se conocen las longitudes de combinacion
    # maxima y minima, las partidas mas cortas para ambos casos
    I=1
    while (( $I <= $NO_GAMES )); do

        LINE_LENGTH=$(cat $STATS_FILE |\
                      head -"$I" |\
                      tail -1 |\
                      cut -f $LENGTH_POS -d "|")

        LINE_DURATION=$(cat $STATS_FILE |\
                        head -"$I" |\ 
                        tail -1 |\
                        cut -f $DURATION_POS -d "|")

        if (( $LINE_LENGTH == $MIN_LENGTH\
           && $LINE_DURATION < $SHORT_L_GAME_DURATION )); then
                SHORT_L_GAME_DURATION=$LINE_DURATION
                SHORT_L_GAME_I=$I
        fi

        if (( $LINE_LENGTH == $MAX_LENGTH\
           && $LINE_DURATION < $LONG_L_GAME_DURATION )); then
                LONG_L_GAME_DURATION=$LINE_DURATION
                LONG_L_GAME_I=$I
        fi    

        I=$(($I+1))

    done
    
    # Calculamos longitud media
    MEAN_LENGTH=$((MEAN_LENGTH / $NO_GAMES))
    
    # Calculamos tiempo de juego medio
    MEAN_DURATION=$((TOTAL_PLAY_TIME / $NO_GAMES))  

    # Tomamos datos de la partida mas corta
    SHORTEST=$(cat $STATS_FILE | head -"$MIN_DURATION_I" | tail -1)

    # Tomamos datos de la partida mas larga
    LONGEST=$(cat $STATS_FILE | head -"$MAX_DURATION_I" | tail -1)

    # Tomamos datos de la partida mas corta (con la combinacion mas corta)
    SHORT_LEN_SHORT_GAME=$(cat $STATS_FILE | head -"$SHORT_L_GAME_I" | tail -1)

    # Tomamos datos de la partida mas corta /con la combinacion mas larga)
    LONG_LEN_SHORT_GAME=$(cat $STATS_FILE | head -"$LONG_L_GAME_I" | tail -1)


    # Si no existe el fichero temporal de estadisticas, se crea
    if ! [[ -e "$TEMP_FILE" ]]; then
        touch "$TEMP_FILE"
        if (( $? != 0)); then
            exit 2 # Si hay un error al crearlo, se termina con error
        fi
    fi


# Esto es utilizado para testear el programa

    #echo "Informacion partida:"
    #echo -e "\tPID|FECHA|HORA|INTENTOS|TIEMPO|LONGITUD|COMBINACION"
    #echo
    #echo "Numero total partidas: $NO_GAMES partidas"
    #echo "Longitud de combinacion media: $MEAN_LENGTH digitos"
    #echo "Duracion media de juego: $MEAN_DURATION s"
    #echo "Tiempo total de juego: $TOTAL_PLAY_TIME s"
    #echo "Informacion juego mas corto: $SHORTEST"
    #echo "Informacion juego mas largo: $LONGEST"
    #echo "Informacion juego mas corto (combinacion mas corta)"
    #echo -e "\t$SHORT_LEN_SHORT_GAME"
    #echo "Informacion juego mas corto (combinacion mas larga)"
    #echo -e "\t$LONG_LEN_SHORT_GAME"


    # Volcamos toda la informacion al fichero temporal
    # (si existiera, se sobreescribe)
    echo "$NO_GAMES" | cat > "$TEMP_FILE"
    echo "$MEAN_LENGTH" | cat >> "$TEMP_FILE"
    echo "$MEAN_DURATION" | cat >> "$TEMP_FILE"
    echo "$TOTAL_PLAY_TIME" | cat >> "$TEMP_FILE"
    echo "$SHORTEST" | cat >> "$TEMP_FILE"
    echo "$LONGEST" | cat >> "$TEMP_FILE"
    echo "$SHORT_LEN_SHORT_GAME" | cat >> "$TEMP_FILE"
    echo "$LONG_LEN_SHORT_GAME" | cat >> "$TEMP_FILE"

    exit 0 # Todo correcto
else
    exit 1 # Formato de argumentos incorrecto
fi
