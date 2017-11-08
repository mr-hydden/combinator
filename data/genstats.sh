#!/bin/bash

# gestats.sh FILE

STATS_FILE=$1 # Fichero de estadisticas

LENGTH_POS=6    # Posicion del campo longitud en el formato 
                # del fichero de estadisticas

DURATION_POS=5  # Posicion del campo tiempo de juego en el formato
                # del fichero de estadisticas

NO_GAMES=        # Numero de partidas
MEAN_LENGTH=     # Longitud media
MEAN_DURATION=   # Tiempo de juego medio
TOTAL_PLAY_TIME= # Tiempo total de juego

SHORTEST=   # Informacion de la partida mas corta
LONGEST=    # Informacion de la partida mas larga

                        # Informacion de las partidas mas cortas
SHORT_LEN_SHORT_GAME=       # Con la combinacion mas corta
LONG_LEN_SHORT_GAME=        # Con la combinacion mas larga


# Calculamos con el numero de juego (coincidente con el numero de lineas)
NO_GAMES=$(cat $STATS_FILE | wc -l)


# Inicializamos
MEAN_LENGTH=0
MEAN_DURATION=0
TOTAL_PLAY_TIME=0

MIN_DURATION=$( cat $STATS_FILE | head -n 1 | cut -f $DURATION_POS -d "|" )
MAX_DURATION=$( cat $STATS_FILE | head -n 1 | cut -f $DURATION_POS -d "|" )
MIN_LENGTH=$( cat $STATS_FILE | head -n 1 | cut -f $LENGTH_POS -d "|" )
MAX_LENGTH=$( cat $STATS_FILE | head -n 1 | cut -f $LENGTH_POS -d "|" )

MIN_LENGTH_I=1      # Linea correspondiente a la partida de mas duracion, etc.
MAX_LENGTH_I=1      #
MIN_DURATION_I=1    #
MAX_DURATION_I=1    #

SHORT_L_GAME_I=1    # Linea correspondiente a las partidas mas cortas
LONG_L_GAME_I=1     # con la combinacion mas corta y mas larga

SHORT_L_GAME_DURATION=$MIN_DURATION # Duracion de las partidas mas cortas
LONG_L_GAME_DURATION=$MIN_DURATION  # con la combinacion mas corta y mas larga

# Recorremos linea a linea, haciendo:
    # Sumar longitudes, para calcular media
    # Sumar tiempos de juego, para calcular medio y total
    # Buscar tiempos maximo y minimo, y guardar el numero de linea
    # Buscar longitud maxima y minima, para luego buscar
        # partidas mas cortas para ambas
I=1
while (( $I <= $NO_GAMES )); do

    LINE_LENGTH=$( cat $STATS_FILE | head -n $I | tail -n 1 | cut -f $LENGTH_POS -d "|" )
    LINE_DURATION=$( cat $STATS_FILE | head -n $I | tail -n 1 | cut -f $DURATION_POS -d "|" )

    ((MEAN_LENGTH += $LINE_LENGTH))
    ((TOTAL_PLAY_TIME += $LINE_DURATION))

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

I=1
while (( $I <= $NO_GAMES )); do

    LINE_LENGTH=$( cat $STATS_FILE | head -n $I | tail -n 1 | cut -f $LENGTH_POS -d "|" )
    LINE_DURATION=$( cat $STATS_FILE | head -n $I | tail -n 1 | cut -f $DURATION_POS -d "|" )

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

MEAN_LENGTH=$((MEAN_LENGTH / $NO_GAMES))        # Calculamos longitud media
MEAN_DURATION=$((TOTAL_PLAY_TIME / $NO_GAMES))  # Calculamos tiempo de juego medio
SHORTEST=$( cat $STATS_FILE | head -n $MIN_DURATION_I | tail -n 1)
LONGEST=$( cat $STATS_FILE | head -n $MAX_DURATION_I | tail -n 1)
SHORT_LEN_SHORT_GAME=$( cat $STATS_FILE | head -n $SHORT_L_GAME_I | tail -n 1)
LONG_LEN_SHORT_GAME=$( cat $STATS_FILE | head -n $LONG_L_GAME_I | tail -n 1)


echo "Informacion partida:"
echo -e "\tPID|FECHA|HORA|INTENTOS|TIEMPO|LONGITUD|COMBINACION"
echo
echo "Numero total partidas: $NO_GAMES partidas"
echo "Longitud de combinacion media: $MEAN_LENGTH digitos"
echo "Duracion media de juego: $MEAN_DURATION s"
echo "Tiempo total de juego: $TOTAL_PLAY_TIME s"
echo "Informacion juego mas corto: $SHORTEST"
echo "Informacion juego mas largo: $LONGEST"
echo "Informacion juego mas corto (combinacion mas corta)"
echo -e "\t$SHORT_LEN_SHORT_GAME"
echo "Informacion juego mas corto (combinacion mas larga)"
echo -e "\t$LONG_LEN_SHORT_GAME"


exit 0
