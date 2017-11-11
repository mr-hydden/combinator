#!/bin/bash


#***********CONSTANTES**************

MIN_LEN=2          # Longitudes maxima y minima permitidas
MAX_LEN=6          #

NEW_LENGTH_G=      # Para recoger los datos de conf_if
NEW_STATS_FILE_G=  #

CONF_FILE_NAME_DEFAULT='conf.cfg'           # Valores por defecto de los nombres 
CONF_FILE_PATH_DEFAULT=$PWD                 # y directorios de los ficheros
STATS_FILE_NAME_DEFAULT='estadisticas.txt'  # del script
STATS_FILE_PATH_DEFAULT=$PWD                #

# Macros de permisos
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
#   clprevln ->Limpia linea de texto en la terminal                           #
#                                                                             #
#   perm ->Devuelve permisos de un fichero o directorio                       #
#                                                                             #
#   test_confile_format-> Comprueba que el formato del fichero de             #
#                         de configuracion es correcto.                       #
#                                                                             #
#   init_confile-> Crea un nuevo fichero de configuracion por defecto         #
#                                                                             #
#   chpath-> Cambia la ruta al fichero de estadisticas en el fichero de       #
#             configuracion                                                   #
#                                                                             #
#   chpath-> Cambia la longitud de combinacion en el fichero de configuracion #
#                                                                             #
#   conf_if-> Muestra una interfaz de configuracion, recoge datos y realiza   #
#             los cambios pertinentes                                         #
#                                                                             #
#   group_if-> Muestra un mensaje con los componentes del grupo               #
#                                                                             #
#   init_stats_file
#
#   updatestats
#
#   genstats
#
#*****************************************************************************#


# ***********************************************
# clprevln                                      *
# ***********************************************
# Limpia la linea anterior y deja el cursor     *
# sobre ella.                                   *
#                                               *
        function clprevln(){ 
# ***********************************************
    # Para funcionar sobre una terminal de 80 caracteres
    # de ancho
    echo -en "\033[F"
    echo -n '                                        '  # 80 espacios
    echo '                                        '     #
    echo -en "\033[F"
}



# ***********************************************
# perm                                          *
# ***********************************************
# Comprueba los permisos del fichero o          *
# o directorio $1                               *
#                                               *
            function perm() {                         
# ***********************************************
#
    # Usage:
    #   perm FILE

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

    # Usage:
    #   init_stats_file FILE

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
            STATS_FILE_PATH=$STATS_FILE_PATH_DEFAULT
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


# ***********************************************
# updatestats                                   *
# ***********************************************
# Incorpora una nueva entrada con los datos de  *
# una partida al fichero de estadisticas        *
#                                               *
            function updatestats() {                         
# ***********************************************

# Usage:
#   updatestats STATS_FILE A B C D E F G
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
    # Return
    #
    #   0 si tiene exito
    #
    #   1 si los argumentos son erroneos
    #
    #   2 si hay algun problema con el fichero


    # Debe haber 8 argumentos obligatoriamente
    if [ $# -eq 8 ]; then

    # Recogemos los argumentos en variables de nombre mas legible
        local STATS_FILE=$1
        local GAME_PID=$2
        local GAME_DATE=$3
        local GAME_TIME=$4
        local NO_ATTEMPTS=$5
        local GAME_DURATION=$6
        local COMB_LENGTH=$7
        local COMBINATION=$8

        if ! [[ $STATS_FILE =~ .*"$STATS_FILE_NAME_DEFAULT" ]]; then
            return 2 # El fichero debe llamarse $STATS_FILE_NAME_DEFAULT
        fi

        # . y .. no son wildcards para el globbing, asi que
        # cambiamos . por $PWD, y .. por $OLDPWD
        if [[ $STATS_FILE =~ "../.*$STATS_FILE_NAME_DEFAULT" ]]; then
            PPWD=$(dirname "$PWD")
            STATS_FILE=$(echo $STATS_FILE | sed "s:\.\./\(.*\):$PPWD/\1:")
        elif [[ $STATS_FILE =~ "./.*$STATS_FILE_NAME_DEFAULT" ]]; then
            STATS_FILE=$(echo $STATS_FILE | sed "s:\./\(.*\):$PWD/\1:")
        fi

        # Si el fichero no existe, lo creamos
        if ! [[ -e $STATS_FILE ]]; then
            init_stats_file $STATS_FILE
            if (( $? != 0 )); then
                return 2 # Error con el fichero
            fi
        fi

        # Comprobamos permisos del fichero; si no se puede escribir, 
        # termina con error
        declare -i FIL_PERM=$(perm "$STATS_FILE") 
        if ! (( (( $FIL_PERM & $W_PERM )) != 0 )); then
            return 2 # No podemos escribir en el fichero
        else
            echo -n "$GAME_PID|$GAME_DATE|$GAME_TIME|$NO_ATTEMPTS|"\
            | cat >> "$STATS_FILE"
            echo "$GAME_DURATION|$COMB_LENGTH|$COMBINATION"\
            | cat >> "$STATS_FILE"
            return 0
        fi
        
    else
        return 1; # Error en el formato de los argumentos
    fi
}



# ***********************************************
# test_stats_format                             *
# ***********************************************
# Devuelve 0 si el formato de la linea $1 es el *
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
    local DATA_FORMAT='^[0-9][0-9]*|' # PID
    DATA_FORMAT+='.*|.*|'             # Fecha y hora
    DATA_FORMAT+='[0-9][0-9]*|'       # Numero de intentos
    DATA_FORMAT+='[0-9][0-9]*|'       # Tiempo de juego
    DATA_FORMAT+='[0-9][0-9]*|'       # Longitud de la combinacion
    DATA_FORMAT+='[0-9][0-9]*$'       # Combinacion

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



# ***********************************************
# genstats                                      *
# ***********************************************
# Genera las estadisticas requeridas, que       *
# escribe en un fichero temporal, a partir de   *
# la informacion en un fichero de estadisticas  *
# con el formato adecuado
#                                               *
            function genstats() {                         
# ***********************************************

# Usage:
#   gestats STATSFILE
#
    # Return:
    #
    #   0 si tiene exito
    #
    #   1 si los argumentos son incorrectos
    #
    #   2 si hay algun problema con el fichero de estadisticas o el temporal

    # Constantes
    #===========================================================================

    local LENGTH_POS=6    # Posicion del campo longitud en el formato 
                          # del fichero de estadisticas

    local DURATION_POS=5  # Posicion del campo tiempo de juego en el formato
                          # del fichero de estadisticas

    local TEMP_FILE="$PWD/stats.tmp" # Fichero temporal. El modulo llamador
                                     # debe encargarse de borrarlo

    #ERROR_FILE="$PWD/statserrlog.tmp"  <- Se ha dejado para debugging, aunque
    #                                      tal  vez  se  podria  incluir en la
    #                                      version  final. Es un fichero en el
    #                                      que  se  registran  las  lineas mal
    #                                      formateadas   en   el   fichero  de 
    #                                      estadisticas.

    #===========================================================================



    # Variables
    #===========================================================================
    local NO_GAMES=        # Numero de partidas
    local MEAN_LENGTH=     # Longitud media
    local MEAN_DURATION=   # Tiempo de juego medio
    local TOTAL_PLAY_TIME= # Tiempo total de juego

    local SHORTEST=   # Informacion de la partida mas corta
    local LONGEST=    # Informacion de la partida mas larga

                            # Informacion de las partidas mas cortas
    local SHORT_LEN_SHORT_GAME=       # Con la combinacion mas corta
    local LONG_LEN_SHORT_GAME=        # Con la combinacion mas larga
    #===========================================================================

    if (( $# == 1)); then

        # Fichero de estadisticas
        STATS_FILE=$1
        if ! [[ -e $STATS_FILE ]]; then
            return 2 # Si el fichero de estadisticas no existe, no hace nada
                   # y devuelve error
        fi 

        # Calculamos con el numero de juego (coincidente con el numero de 
        # lineas, en principio. Si hay lineas con formato incorrecto, 
        # se corregira)
        NO_GAMES=$(cat $STATS_FILE | wc -l)


    # Inicializamos ----------------------------------------------------------//

        MEAN_LENGTH=0
        MEAN_DURATION=0
        TOTAL_PLAY_TIME=0

        # Seria facil asignar la primera linea, pero si el formato es incorrecto
        # no nos interesa, elegimos la primera que sea correcta
        LINE=1
        while (($LINE <= NO_GAMES ))
        do
            test_line_format $(cat $STATS_FILE | head -"$LINE" | tail -1)
            if (( $? == 0 )); then
                break            
            else    
                LINE=$(($LINE+1))
            fi
        done

        if (( $LINE > $NO_GAMES )); then
            return 2 # Formato del fichero de estadisticas totalmente incorrecto
        fi
            
        MIN_DURATION=$(cat $STATS_FILE | \
                       head -"$LINE" | \
                       cut -f $DURATION_POS -d "|")

        MAX_DURATION=$(cat $STATS_FILE | \
                       head -"$LINE" | \
                       cut -f $DURATION_POS -d "|")

        MIN_LENGTH=$(cat $STATS_FILE | \
                     head -"$LINE" | \
                     cut -f $LENGTH_POS -d "|")

        MAX_LENGTH=$(cat $STATS_FILE | \
                     head -"$LINE" | \
                     cut -f $LENGTH_POS -d "|")

        MIN_LENGTH_I=$LINE   # Linea que contiene partida mas larga, corta, etc.
        MAX_LENGTH_I=$LINE   #
        MIN_DURATION_I=$LINE #
        MAX_DURATION_I=$LINE #

        SHORT_L_GAME_I=$LINE  # Linea correspondiente a las partidas mas cortas
        LONG_L_GAME_I=$LINE   # con la combinacion mas corta y mas larga

        SHORT_L_GAME_DURATION=$MIN_DURATION # Duracion de las partidas mas 
        LONG_L_GAME_DURATION=$MIN_DURATION  # cortas con la combinacion mas 
                                            # corta y mas larga, respectivamente

        #if ! [[ -e "$ERROR_FILE" ]]; then <-------------- Ver nota bucle abajo 
        #    touch "$ERROR_FILE"
        #    if (( $? != 0)); then
        #        return 2
        #    fi
        #fi

    # Fin inicializacion -----------------------------------------------------//



        # Recorremos linea a linea, haciendo:
            # Sumar longitudes, para calcular media
            # Sumar tiempos de juego, para calcular medio y total
            # Buscar tiempos maximo y minimo, y guardar el numero de linea
            # Buscar longitud maxima y minima, para luego buscar
                # partidas mas cortas para ambas
        I=1
        WRONG_LINES_NO=0
        while (( $I <= $NO_GAMES )); do

            # Si el formato de una linea no es adecuado, la saltamos
            LINE=$( cat $STATS_FILE | head -"$I" | tail -1 )
            test_line_format "$LINE"
            if (( $? != 0 )); then
                I=$(($I+1))
                WRONG_LINES_NO=$(($WRONG_LINES_NO+1))
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
            
            test_line_format $(cat $STATS_FILE | head -"$I" | tail -1)
            if (( $? != 0 )); then
                I=$(($I+1))
                continue        
            fi

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
        
        # Calculamos numero de juegos en funcion de las lineas erroneas
        NO_GAMES=$(($NO_GAMES-$WRONG_LINES_NO))

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
                return 2 # Si hay un error al crearlo, se termina con error
            fi
        fi


    # Esto es utilizado para testear el programa

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

        return 0 # Todo correcto
    else
        return 1 # Formato de argumentos incorrecto
    fi

}


# ***********************************************
# test_confile_format                           *
# ***********************************************
# Comprueba que el formato del fichero  de      *
# configuracion es el adecuado                  *
#                                               *
            function test_confile_format() {                         
# **********************************************
    
    # Usage:
    #   test_confile_format CONF_FILE

    #
    # Return: 
    #   0 si tiene exito
    #   1 si el formato de los argumentos no es el correcto
    #   2 si el formato del fichero no es el adecuado
    #
    # El formato del fichero debe ser:
    #
    #==============================================================
    #LONGITUD=N
    #ESTADISTICAS=/path/to/statistics/file\n^D
    #==============================================================
    #
    # donde N es un numero entero y '\n^D' indica salto de linea y fin
    # de fichero

    if (( $# == 1 )); then
        
        # Contamos el numero de lineas
        declare -i local LINENO
        local LINENO=$(cat $1 2> /dev/null | wc -l)
        if (( $LINENO == 2 )); then

            # Comprobamos cada linea
            #
            # Lo siguiente seria mejor con patrones multilinea, pero
            # no se usarlos con sed, y no me quiero arriesgar a que 
            # pcregrep no funcione sobre encina.fis.usal.es
            
            head -1 $1 2> /dev/null | grep '^LONGITUD=[0-9]$' &> /dev/null
            local BAD_FORMAT_LINE1=$?
            tail -1 $1 2> /dev/null | grep '^ESTADISTICAS=.*$' &> /dev/null
            local BAD_FORMAT_LINE2=$?

            if (( $BAD_FORMAT_LINE1 != 0 || $BAD_FORMAT_LINE2 != 0 )); then
                return 2 # Formato de las lineas incorrecto
            fi

            return 0 # Formato correcto

        else
            return 2 # Numero de lineas incorrecto
        fi
    else
        return 1
    fi

}

# ***********************************************
# init_confile                                *
# ***********************************************
# Crea el fichero de configuracion con nombre   *
# con nombre $1                                 *
#                                               *
            function init_confile() {                         
# **********************************************

    # Usage:
    #   init_confile FILE

    # Return:
    #   0 si tiene exito
    #
    #   1 si recibe argumentos erroneos
    #
    #   2 si no se pudo crear el fichero o directorio
    #
    #   3 si no se puede modificar el fichero
    #        

    local CONF_FILE=$1
    local CONF_FILE_PATH
    local CONF_FILE_NAME

    if [ $# -eq 1 ]; then
        
        # Separamos nombre y ruta del fichero para trabajarlos por separado
        CONF_FILE_PATH=$(echo $CONF_FILE | sed -n 's:\(.*\)/.*$:\1:p')
        CONF_FILE_NAME=$(echo $CONF_FILE | sed -n 's:.*/\(.*\)$:\1:p')

        # Si sed no separa adecuadamente, toma $1 como un nombre de fichero y
        # lo crea en el directorio $CONF_FILE_PATH_DEFAULT
        if [[ -z "$CONF_FILE_NAME" || -z "$CONF_FILE_PATH " ]];then
            CONF_FILE_NAME=$CONF_FILE
            CONF_FILE_PATH=$CONF_FILE_PATH_DEFAULT
        fi

        # Si el directorio no existe, lo creamos, con todos los intermedios
        if ! [[ -e "$CONF_FILE_PATH" ]]; then
            mkdir -p "$CONF_FILE_PATH" &> /dev/null
            if (( $? != 0 )); then  # Si el directorio no se creo correctamente
                return 2            # (porque no hay permisos, por ejemplo)
            fi
        fi
        
        # Comprobamos que podemos trabajar en el directorio que contiene
        # el fichero de configuracion
        declare -i local DIR_PERM=$(perm "$CONF_FILE_PATH") 
        if (( $DIR_PERM == $RWX_PERM )); then

            cd "$CONF_FILE_PATH"

            if ! [[ -e "$CONF_FILE_NAME" ]]; then
                touch "$CONF_FILE_NAME"   # Como tenemos permisos W, 
                                            # se crea sin problema
            fi

            declare -i local FIL_PERM=$(perm "$CONF_FILE_NAME") 
                                                    # En principio
                                                    # no hace falta comprobar
                                                    # el valor de retorno de 
                                                    # perm, se los he 
                                                    # proporcionado mas como 
                                                    # una medida de seguridad, 
                                                    # o en caso de necesitar
                                                    # debugging
                

            # Si tenemos permisos de escritura
            # escribimos el fichero en el formato adecuado
            if (( (( $FIL_PERM & $W_PERM )) != 0 )); then    
                echo 'LONGITUD=0' | cat > "$CONF_FILE_NAME" # Se crea de cero
                echo "ESTADISTICAS=$STATS_FILE_PATH_DEFAULT/estadisticas.txt" |\
                cat >> "$CONF_FILE_NAME"

                return 0
            else
                return 3 # No podemos escribir en el fichero
            fi

        else
            return 3 # No hay permisos en el directorio
        fi
    else
        return 1 # Argumentos erroneos en numero
    fi
}



# ***********************************************
# chpath()                                      *
# ***********************************************
# Funcion que modifica la ruta al fichero de    *
# estadisticas en el fichero de configuracion   *
#                                               *
            function chpath() {                         
# ***********************************************

    # Requiere 2 argumentos obligatorios: una ruta a un fichero y una cadena
    # Uso: chpath FILE STRING
    # Cambia el fichero FILE, que tiene el siguiente formato
    #
    #==============================================================
    #LONGITUD=N
    #ESTADISTICAS=/path/to/statistics/file\n^D
    #==============================================================
    #
    # /path/to/statistics/file se cambiara por STRING
    #
    # Esta funcion espera un fichero con permisos de escritura y lectura
    # No comprueba la validez de la nueva ruta STRING.
    # Si no puede actuar sobre el fichero, devuelve error y no hace cambios.
    # Si la ruta no es valida, la ESCRIBE IGUALMENTE.
    #
    # Return values:
    #
    #   0 si tiene exito
    #
    #   1 si los argumentos son invalidos (en numero)
    #
    #   2 si no pudo abrir o escribir en el fichero

    local CONF_FILE=
    local NEW_STATS_FILE=

    if [ $# -eq 2 ]; then

        CONF_FILE=$1
        NEW_STATS_FILE=$2

        # Separamos la ruta y el nombre del fichero, para poder trabajar con
        # perm y comprobar los permisos por separado
#        local CONF_FILE_PATH=$(echo $CONF_FILE |\
#                               sed -n 's:\(.*\)/.*$:\1:p')
#        local CONF_FILE_NAME=$(echo $CONF_FILE |\
#                               sed -n 's:.*/\(.*\)$:\1:p')

        
#        if ! [[ -e "$CONF_FILE_PATH"/"$CONF_FILE_NAME" ]]; then
#            declare -i local DIR_PERM=$(perm "$CONF_FILE_PATH")
#            if (( $DIR_PERM == $RWX_PERM )); then
#                init_confile "$CONF_FILE_NAME" "$CONF_FILE_PATH"
#                if [[ $? -ne 0 ]]; then
#                   return 2 # Error en la creacion del fichero
#                fi
#            else
#                return 2 # No se puede crear el fichero por falta de permisos
#            fi
#        fi
        
#        test_confile_format "$CONF_FILE"
#        if (( $? != 0 )); then
#            return 3 # Formato de fichero incorrecto
#        fi
	
	# sed -i "s:ESTADISTICAS=.*:ESTADISTICAS=$NEW_STATS_FILE:" "$CONF_FILE"\
	# &> /dev/null
	# Esto es ideal, pero no funciona sobre encina

        # Como no se puede usar el mismo fichero de entrada y salida, creamos
        # uno temporal y lo renombramos
        local TMP_FILE="$CONF_FILE_PATH_DEFAULT/.conf.cfg"
        touch "$TMP_FILE"

        sed "s:ESTADISTICAS=.*:ESTADISTICAS=$NEW_STATS_FILE:" "$CONF_FILE" \
        > "$TMP_FILE"
        mv "$TMP_FILE" "$CONF_FILE" # Lo sobreescribe si existe

    else
        return 1 # Numero de argumentos no valido
    fi
}



# ***********************************************
# chlength()                                    *
# ***********************************************
# Funcion que modifica la longitud por defecto  *
# en el fichero de configuracion                *
#                                               *
            function chlength() {                         
# ***********************************************

    # Requiere 2 argumentos obligatorios: una ruta a un fichero y un entero N
    # Uso: chpath FILE N
    # Cambia el fichero FILE, que tiene el siguiente formato
    #
    #==============================================================
    #LONGITUD=N
    #ESTADISTICAS=/path/to/statistics/file\n^D
    #==============================================================
    #
    # K se cambia por N
    #
    # Esta funcion espera un fichero con permisos de escritura y lectura. 
    # No comprueba la validez del entero N.
    # Si no puede actuar sobre el fichero, devuelve error y no hace cambios.
    # Si N no es un numero entero, lo ESCRIBE IGUALMENTE.
    #
    # Return values:
    #   0 si tiene exito
    #
    #   1 si los argumentos son invalidos (en numero)
    #
    #   2 si no pudo abrir o escribir en el fichero

    local CONF_FILE=$1
    local NEW_LENGTH=$2

    if [ $# -eq 2 ]; then

#        CONF_FILE=$1
#        if [[ $2 =~ [0-9] ]]; then
#            NEW_LENGTH=$2
#        else
#           return 1
#        fi

        # Separamos la ruta y el nombre del fichero, para poder trabajar con
        # perm y comprobar los permisos por separado
#        local CONF_FILE_PATH=$(echo $CONF_FILE |\
#                               sed -n 's:\(.*\)/.*$:\1:p')
#        local CONF_FILE_NAME=$(echo $CONF_FILE |\
#                               sed -n 's:.*/\(.*\)$:\1:p')

        
#        if [[ ! -e "$CONF_FILE_PATH"/"$CONF_FILE_NAME" ]]; then
#            declare -i local DIR_PERM=$(perm "$CONF_FILE_PATH")
#            if (( $DIR_PERM == $RWX_PERM )); then
#                init_confile "$CONF_FILE_NAME" "$CONF_FILE_PATH"
#                if [[ $? -ne 0 ]]; then
#                    return 2 # Error en la creacion del fichero
#                fi
#            else
#                return 2 # No se puede crear el fichero por falta de permisos
#            fi
#        fi

#        test_confile_format "$CONF_FILE"
#        if (( $? != 0 )); then
#            return 3 # Formato de fichero incorrecto
#        fi

        # sed -i "s:LONGITUD=.*:LONGITUD=$NEW_LENGTH:" "$CONF_FILE"\
        # &> /dev/null
	# Esto no funciona sobre encina, de ahi que este comentado
    local TMP_FILE="$CONF_FILE_PATH_DEFAULT/.conf.cfg"
    touch "$TMP_FILE"

	sed "s:LONGITUD=.*:LONGITUD=$NEW_LENGTH:" "$CONF_FILE" \
    > "$TMP_FILE"
    mv "$TMP_FILE" "$CONF_FILE" # Lo sobreescribe si existe

    else
        return 1 # Numero de argumentos no valido
    fi
}


# ***********************************************
# chconf()                                      *
# ***********************************************
# Funcion que modifica el fichero de            *
# configuracion                                 *
#                                               *
            function chconf() {                         
# ***********************************************

    # Usage:
    #   chconf [-l LENGTH | --length LENGTH]\
    #          [-s STATS_FILE | --statsfile STATS_FILE]

    # Return:
    #
    #   0 si tiene exito
    #
    #   1 formato de argumentos incorrecto
    #
    #   2 opcion invalida
    #
    #   3 error con el fichero
    #
    #   4 formato de fichero de configuracion incorrecto
        
    local CONF_FILE
    local LENGTH
    local STATS_FILE

    # Los formatos de llamada son 
    #   a) chconf.sh CONFIGURATION_FILE -l N
    #   b) chconf.sh CONFIGURATION_FILE -s /path/to/statsfile
    #   c) chconf.sh CONFIGURATION_FILE -l N -s /path/to/statsfile (o viceversa)
    #  por lo que los argumentos deben ser 3 o 5

    if (( $# == 3 || $# == 5 )); then

        CONF_FILE=$1
        shift

        # Si el fichero no existe, se intenta crear uno con el formato adecuado
        # Si no se puede, termina con codigo de error
        if ! [[ -e "$CONF_FILE" ]]; then
            init_confile "$CONF_FILE"
            if [[ $? -ne 0 ]]; then
                return 3 # Error en la creacion del fichero
            fi
        fi

        # Comprobamos permisos del fichero; si no se puede escribir o leer, 
        # termina con error
        declare -i FIL_PERM=$(perm "$CONF_FILE") 
        if ! (( (( $FIL_PERM & $RW_PERM )) != 0 )); then
            return 3 # No podemos escribir o leer en el fichero
        fi

        # Si el fichero existe, pero no tiene el formato adecuado, se termina
        # con error. Si este script fuera interactivo, podriamos dar la opcion
        # de sobreescribir; seria facil realizar el cambio si se considera
        # oportuno.
        test_confile_format "$CONF_FILE"
        if (( $? != 0 )); then
            return 4 # Formato de fichero incorrecto
        fi
        
        # Parseamos el resto de argumentos. Para esta funcion se ha hecho con
        # opciones; dado que son scripts internos, en el resto de ellos se ha
        # prescindido por simplicidad, aunque sean menos flexibles.

        while : # Por defecto, si se le pasa algo como
                #   chconf -s FILE1 -s FILE2 -s FILE3 ...
                # toma el ultimo valor pasado. Igual para -l
        do
            case $1 in
                -l | --length)
                    if [[ $2 =~ [0-9] ]]; then
                        LENGTH=$2
                        shift 2
                    else
                        return 1 # Error de formato de argumentos
                    fi
                ;;
                
                -s | --statsfile)
                    if [[ $2 =~ .*/?"$STATS_FILE_NAME_DEFAULT" ]]; then

                        # . y .. no son wildcards para el globbing, asi que
                        # cambiamos . por $PWD, y .. por $OLDPWD
                        if [[ $2 =~ "../.*$STATS_FILE_NAME_DEFAULT" ]]; then
                            PPWD=$(dirname "$PWD")
                            STATS_FILE=$(echo $2 | sed "s:\.\./\(.*\):$PPWD/\1:")
                        elif [[ $2 =~ "./.*$STATS_FILE_NAME_DEFAULT" ]]; then
                            STATS_FILE=$(echo $2 | sed "s:\./\(.*\):$PWD/\1:")
                        else
                            STATS_FILE=$2
                        fi
                        
                        shift 2
                    else
                        return 1 # Error de formato de argumentos
                    fi
                ;;

                -*)
                    return 2 # Opcion inexistente
                ;;
            
                *)
                    break # No quedan argumentos
                ;;
            esac
        done
        
        # Si se sale del bucle y quedan argumentos (porque eran 3 o 5 pero no 
        # con el formato adecuado, por ejemplo chconf.sh -l N foo bar), estos
        # son erroneos, y se termina con codigo de error
        if (( $# > 0 )); then
            return 1 # Argumentos erroneos
        fi

        # En otro caso, todo esta bien, se hacen los cambios pertinentes
        if [[ -n "$LENGTH" ]]; then
            chlength "$CONF_FILE" "$LENGTH"
        fi

        if [[ -n "$STATS_FILE" ]]; then
            chpath "$CONF_FILE" "$STATS_FILE"
        fi

        return 0

    else
        return 1 # Numero de argumentos invalido
    fi

}

# ***********************************************
# conf_if()                                     *
# ***********************************************
# Muestra un menu de configuracion y devuelve   *
# datos de usuario en las variables globales    *
# NEW_LENGTH_G y NEW_STATS_FILE_G               *
#                                               *
            function conf_if() {                         
# ***********************************************

    # Usage:
    #   conf_if

    # Return 0

    local OPTION
    local NEW_STATS_FILE
    local NEW_LENGTH

    clear

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
    echo '          Puede  realizar los cambios que desee.  Para terminar          '
    echo '          seleccione volver al menu principal.                           '
    echo
    echo '                  Opciones                                               '
    echo
    echo '                      a) Cambiar longitud de combinacion                 '
    echo '                      b) Cambiar fichero de estadisticas                 '
    echo '                      c) Volver al menu principal                        '
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
                read -p '              Nueva longitud: ' NEW_LENGTH

                while ! [[ "$NEW_LENGTH" =~ ^[0-9]$ && 
                           "$NEW_LENGTH" -ge "$MIN_LEN" && 
                           "$NEW_LENGTH" -le "$MAX_LEN"  ]]
                do
                    clprevln
                    read -p '              Introduzca un valor entre 2 y 6: ' \
                    NEW_LENGTH
                done
                

                chconf "$CONF_FILE_PATH_DEFAULT/$CONF_FILE_NAME_DEFAULT" \
                -l "$NEW_LENGTH"

                clprevln # Limpiamos lo escrito
                echo '              Cambio realizado con exito'

                continue
            ;;

            b)
                read -p '              Nuevo fichero de estadisticas: ' \
                NEW_STATS_FILE

                while ! [[ "$NEW_STATS_FILE" =~ .*/?"$STATS_FILE_NAME_DEFAULT" ]]
                do
                    
                    clprevln; clprevln # Necesitamos dos lineas

                    echo -n "      El nombre del fichero de configuracion debe ser: "
                    echo "'$STATS_FILE_NAME_DEFAULT'"
                    read -p '      Introduzca un fichero valido: ' NEW_STATS_FILE
                done
                
                clprevln; clprevln # Limpiamos lo escrito y nos situamos
                echo

                chconf "$CONF_FILE_PATH_DEFAULT/$CONF_FILE_NAME_DEFAULT" \
                -s "$NEW_STATS_FILE"

                clprevln # Limpiamos lo escrito
                echo '              Cambio realizado con exito'

                continue
            ;;
        
            c)
                NEW_LENGTH_G=$NEW_LENGTH
                NEW_STATS_FILE_G=$NEW_STATS_FILE
                break
            ;;
        esac
    done

    return 0
}


# ***********************************************
# group_if()                                    *
# ***********************************************
# Muestra los integrantes del grupo             *
#                                               *
            function group_if() {                         
# ***********************************************
    
    # Usage:
    #   group_if

    # Return
    #   0

    # Variables
    local RELEASE_DATE=$(date +'%b-%Y')
    local VERSION='v2.13'

    clear

    echo
    echo
    echo
    echo
    echo
    echo
    echo
    echo
    echo -n '                                   '
    echo -n 'Combinator' # 10 caracteres
    echo '                                   '
    echo
    echo -n '                             '
    echo -n "$VERSION"          # v2.13 = 5 caracteres
    echo -n '            '      # Jan-2017= 8 caracteres
    echo -n "$RELEASE_DATE"
    echo '     '  
    echo                                                                                
    echo
    echo
    echo
    echo '         Copyright Samuel Gómez Sánchez, Luis Blázquez Miñambres,'\
         $(date +'%Y')
    echo -n '                              '
    echo -n 'All Rights Reserved.' # 20 caracteres
    echo -n '                              '
    echo
    echo
    echo
    echo
    echo
    echo
    echo
    clprevln
    read -n 1 -p '    Pulse cualquier tecla para volver al menu principal...' A

    return 0
}

###############################################################################
###############################################################################
###############################################################################
###############################################################################

END=0
while (( $END == 0)); do
    
    clear    

    echo -n '****************************************'
    echo '****************************************'
    echo -n '*                                       '
    echo '                                       *'
    echo -n '*                                  '
    echo -n 'COMBINATOR'
    echo '                                  *'
    echo -n '*                                       '
    echo '                                       *'
    echo -n '****************************************'
    echo '****************************************'
    echo

    echo '    J) JUGAR'
    echo '    C) CONFIGURACION'
    echo '    E) ESTADISITICAS'
    echo '    G) GRUPO'
    echo '    S) SALIR'
    read -p '    La Caja Fuerte. Introduzca una opcion >>' OPCION

    case "$OPCION" in
        'J' | 'j')
            continue
        ;;

        'C' | 'c')
            conf_if
            echo "$NEW_LENGTH_G | $NEW_STATS_FILE_G"
            continue
        ;;

        'E' | 'e')
            cat "$STATS_FILE_PATH_DEFAULT/$STATS_FILE_NAME_DEFAULT"             # Temporal, testing...
            sleep 3                                                             #
            updatestats "$STATS_FILE_PATH_DEFAULT/$STATS_FILE_NAME_DEFAULT" \
            '2231' $(date +%m.%d.%Y) $(date +%R) '21' '91' '4' '9012'           #
            cat "$STATS_FILE_PATH_DEFAULT/$STATS_FILE_NAME_DEFAULT"             #
            sleep 3                                                             #
            genstats "$STATS_FILE_PATH_DEFAULT/$STATS_FILE_NAME_DEFAULT"        #
            read -n 1                                                           #
            continue
        ;;

        'G' | 'g')
            group_if
            continue
        ;;

        'S' | 's')
            END=1
        ;;

        *)
            echo 'OPCION INCORRECTA . Intentelo de nuevo'
            sleep 1
        ;;

    esac   
done

exit 0
