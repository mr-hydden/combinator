#!/bin/bash

# gestats.sh FILE






# ***********************************************
# test_stats_format                             *
# ***********************************************
# Devuelve 0 si el formato del fichero $1 es el *
# adecuado, y diferente de 0 si no lo es.       *
#                                               *
            function test_stats_format() {                         
# ***********************************************
    #
    # Return:
    #   0 si tiene exito
    #
    #   1 si el formato de los argumentos es incorrecto
    #
    #   2 si el numero de lineas del fichero es incorrecto
    #
    #   3 si alguna linea tiene formato incorrecto

    # Constantes dependientes del formato del fichero
    local FORMAT_LINENO=8
    local NOGAMES_I=1
    local MEANL_I=2
    local MEAND_I=3
    local TOTALT_I=4
    local DATA1_I=5
    local DATA2_I=6
    local DATA3_I=7
    local DATA4_I=8
    
    local DATA_FORMAT='^.*|.*|.*|.*|.*|.*|.*$'
   

    if [[ $# == 1 ]]; then

        local LINENO=$(cat $1 | wc -l)
        if (( $LINENO != $FORMAT_LINENO )); then
            return 2
        fi

        local NO_GAMES=$(cat $1 | head -"$NOGAMES_I" | tail -1)
        local MEAN_LENGTH=$(cat $1 | head -"$MEANL_I" | tail -1)
        local MEAN_DURATION=$(cat $1 | head -"$MEAND_I" | tail -1)
        local TOTAL_PLAY_TIME=$(cat $1 | head -"$TOTALT_I" | tail -1)
        local DATA1=$(cat $1 | head -"$DATA1_I" | tail -1)
        local DATA2=$(cat $1 | head -"$DATA2_I" | tail -1)
        local DATA3=$(cat $1 | head -"$DATA3_I" | tail -1)
        local DATA4=$(cat $1 | head -"$DATA4_I" | tail -1)

        if ! [[ "$NO_GAMES" =~ [0-9][0-9]* ]]; then
            return 3
        elif ! [[ "$MEAN_LENGTH" =~ [0-9][0-9]* ]]; then
            return 3
        elif ! [[ "$MEAN_DURATION" =~ [0-9][0-9]* ]]; then
            return 3
        elif ! [[ "$TOTAL_PLAY_TIME" =~ [0-9][0-9]* ]]; then
            return 3
        fi

        if ! [[ "$DATA1" =~ "$DATA_FORMAT" ]]; then
            return 3
        elif ! [[ "$DATA2" =~ "$DATA_FORMAT" ]]; then
            return 3
        elif ! [[ "$DATA3" =~ "$DATA_FORMAT" ]]; then
            return 3
        elif ! [[ "$DATA4" =~ "$DATA_FORMAT" ]]; then
            return 3
        fi

        return 0

    else
        return 1

    fi
}


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

    # Constantes dependientes del formato del fichero

    local DATA_FORMAT='^[0-9][0-9]*|.*|.*|[0-9][0-9]*|[0-9][0-9]*|[0-9][0-9]*|[0-9][0-9]*$'

    if [[ $# == 1 ]]; then
        echo $1 | grep $DATA_FORMAT &> /dev/null
        if (( $? == 0 )); then
            return 0
        else
            return 2
        fi
    else
        return 1
    fi
}






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

TEMP_FILE="$PWD/"$TEMP_FILE""

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

    # Si el formato de una linea no es adecuado, la saltamos
    test_line_format $( cat $STATS_FILE | head -"$I" | tail -1 )
    if (( $? != 0 )); then
        I=$(($I+1))
        NO_GAMES=$(($NO_GAMES-1))
        continue
    fi

    LINE_LENGTH=$( cat $STATS_FILE | head -"$I" | tail -1 | cut -f $LENGTH_POS -d "|" )
    LINE_DURATION=$( cat $STATS_FILE | head -"$I" | tail -1 | cut -f $DURATION_POS -d "|" )

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

if ! [[ -e "$TEMP_FILE" ]]; then
    touch "$TEMP_FILE"
    if (( $? != 0))
        return 1
    fi
fi



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

#echo "$NO_GAMES" | cat > "$TEMP_FILE"
#echo "$MEAN_LENGTH" | cat >> "$TEMP_FILE"
#echo "$MEAN_DURATION" | cat >> "$TEMP_FILE"
#echo "$TOTAL_PLAY_TIME" | cat >> "$TEMP_FILE"
#echo "$SHORTEST" | cat >> "$TEMP_FILE"
#echo "$LONGEST" | cat >> "$TEMP_FILE"
#echo "$SHORT_LEN_SHORT_GAME" | cat >> "$TEMP_FILE"
#echo "$LONG_LEN_SHORT_GAME" | cat >> "$TEMP_FILE"

exit 0
