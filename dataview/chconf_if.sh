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
CONFIG_FILE_DEFAULT='conf.cfg'
CONFIG_FILE_PATH_DEFAULT=$PWD
STATS_FILE_DEFAULT='estadisticas.txt'
STATS_FILE_PATH_DEFAULT=$PWD
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
#                                   clprevln                                  #
#                                   perm                                      #
#                                   test_file_format                          #
#                                   init_conf_file                            #
#                                   chpath                                    #
#                                   chlength                                  #
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
    echo -n '                                        ' # 40 espacios
    echo '                                       '     # 39 espacios
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
# test_file_format                              *
# ***********************************************
# Comprueba que el formato del fichero  de      *
# configuracion es el adecuado                  *
#                                               *
            function test_file_format() {                         
# **********************************************
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
# init_conf_file                                *
# ***********************************************
# Crea el fichero de configuracion con nombre   *
# con nombre $1                                 *
#                                               *
            function init_conf_file() {                         
# **********************************************

    # Return:
    #   0 si tiene exito
    #
    #   1 si recibe argumentos erroneos
    #
    #   2 si no se pudo crear el fichero o directorio
    #
    #   3 si no se puede modificar el fichero
    #        

    local CONFIG_FILE=$1
    local CONFIG_FILE_PATH
    local CONFI_FILE_NAME

    if [ $# -eq 1 ]; then
        
        # Separamos nombre y ruta del fichero para trabajarlos por separado
        CONFIG_FILE_PATH=$(echo $CONFIG_FILE | sed -n 's:\(.*\)/.*$:\1:p')
        CONFIG_FILE_NAME=$(echo $CONFIG_FILE | sed -n 's:.*/\(.*\)$:\1:p')

        # Si sed no separa adecuadamente, toma $1 como un nombre de fichero y
        # lo crea en el directorio $CONFIG_FILE_PATH_DEFAULT
        if [[ -z "$CONFIG_FILE_NAME" || -z "$CONFIG_FILE_PATH " ]];then
            CONFIG_FILE_NAME=$CONFIG_FILE
            CONFIG_FILE_PATH=$CONFIG_FILE_PATH_DEFAULT
        fi

        # Si el directorio no existe, lo creamos, con todos los intermedios
        if ! [[ -e "$CONFIG_FILE_PATH" ]]; then
            mkdir -p "$CONFIG_FILE_PATH" &> /dev/null
            if (( $? != 0 )); then  # Si el directorio no se creo correctamente
                return 2            # (porque no hay permisos, por ejemplo)
            fi
        fi
        
        # Comprobamos que podemos trabajar en el directorio que contiene
        # el fichero de configuracion
        declare -i local DIR_PERM=$(perm "$CONFIG_FILE_PATH") 
        if (( $DIR_PERM == $RWX_PERM )); then

            cd "$CONFIG_FILE_PATH"

            if ! [[ -e "$CONFIG_FILE_NAME" ]]; then
                touch "$CONFIG_FILE_NAME"   # Como tenemos permisos W, 
                                            # se crea sin problema
            fi

            declare -i local FIL_PERM=$(perm "$CONFIG_FILE_NAME") 
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
                echo 'LONGITUD=0' | cat > "$CONFIG_FILE_NAME" # Se crea de cero
                echo "ESTADISTICAS=$STATS_FILE_PATH_DEFAULT/estadisticas.txt" |\
                cat >> "$CONFIG_FILE_NAME"

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

    local CONFIG_FILE=
    local NEW_STATS_FILE=

    if [ $# -eq 2 ]; then

        CONFIG_FILE=$1
        NEW_STATS_FILE=$2

        # Separamos la ruta y el nombre del fichero, para poder trabajar con
        # perm y comprobar los permisos por separado
#        local CONFIG_FILE_PATH=$(echo $CONFIG_FILE |\
#                               sed -n 's:\(.*\)/.*$:\1:p')
#        local CONFIG_FILE_NAME=$(echo $CONFIG_FILE |\
#                               sed -n 's:.*/\(.*\)$:\1:p')

        
#        if ! [[ -e "$CONFIG_FILE_PATH"/"$CONFIG_FILE_NAME" ]]; then
#            declare -i local DIR_PERM=$(perm "$CONFIG_FILE_PATH")
#            if (( $DIR_PERM == $RWX_PERM )); then
#                init_conf_file "$CONFIG_FILE_NAME" "$CONFIG_FILE_PATH"
#                if [[ $? -ne 0 ]]; then
#                   return 2 # Error en la creacion del fichero
#                fi
#            else
#                return 2 # No se puede crear el fichero por falta de permisos
#            fi
#        fi
        
#        test_file_format "$CONFIG_FILE"
#        if (( $? != 0 )); then
#            return 3 # Formato de fichero incorrecto
#        fi
	
	# sed -i "s:ESTADISTICAS=.*:ESTADISTICAS=$NEW_STATS_FILE:" "$CONFIG_FILE"\
	# &> /dev/null
	# Esto es ideal, pero no funciona sobre encina

        # Como no se puede usar el mismo fichero de entrada y salida, creamos
        # uno temporal y lo renombramos
        local TMP_FILE="$PWD/.conf.cfg"
        touch "$TMP_FILE"

        sed "s:ESTADISTICAS=.*:ESTADISTICAS=$NEW_STATS_FILE:" "$CONFIG_FILE" \
        > "$TMP_FILE"
        mv "$TMP_FILE" "$CONFIG_FILE" # Lo sobreescribe si existe

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

    local CONFIG_FILE=$1
    local NEW_LENGTH=$2

    if [ $# -eq 2 ]; then

#        CONFIG_FILE=$1
#        if [[ $2 =~ [0-9] ]]; then
#            NEW_LENGTH=$2
#        else
#           return 1
#        fi

        # Separamos la ruta y el nombre del fichero, para poder trabajar con
        # perm y comprobar los permisos por separado
#        local CONFIG_FILE_PATH=$(echo $CONFIG_FILE |\
#                               sed -n 's:\(.*\)/.*$:\1:p')
#        local CONFIG_FILE_NAME=$(echo $CONFIG_FILE |\
#                               sed -n 's:.*/\(.*\)$:\1:p')

        
#        if [[ ! -e "$CONFIG_FILE_PATH"/"$CONFIG_FILE_NAME" ]]; then
#            declare -i local DIR_PERM=$(perm "$CONFIG_FILE_PATH")
#            if (( $DIR_PERM == $RWX_PERM )); then
#                init_conf_file "$CONFIG_FILE_NAME" "$CONFIG_FILE_PATH"
#                if [[ $? -ne 0 ]]; then
#                    return 2 # Error en la creacion del fichero
#                fi
#            else
#                return 2 # No se puede crear el fichero por falta de permisos
#            fi
#        fi

#        test_file_format "$CONFIG_FILE"
#        if (( $? != 0 )); then
#            return 3 # Formato de fichero incorrecto
#        fi

        # sed -i "s:LONGITUD=.*:LONGITUD=$NEW_LENGTH:" "$CONFIG_FILE"\
        # &> /dev/null
	# Esto no funciona sobre encina, de ahi que este comentado
    local TMP_FILE="$PWD/.conf.cfg"
    touch "$TMP_FILE"

	sed "s:LONGITUD=.*:LONGITUD=$NEW_LENGTH:" "$CONFIG_FILE" \
    > "$TMP_FILE"
    mv "$TMP_FILE" "$CONFIG_FILE" # Lo sobreescribe si existe

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
        
    local CONFIG_FILE
    local LENGTH
    local STATS_FILE

    # Los formatos de llamada son 
    #   a) chconf.sh CONFIGURATION_FILE -l N
    #   b) chconf.sh CONFIGURATION_FILE -s /path/to/statsfile
    #   c) chconf.sh CONFIGURATION_FILE -l N -s /path/to/statsfile (o viceversa)
    #  por lo que los argumentos deben ser 3 o 5

    if (( $# == 3 || $# == 5 )); then

        CONFIG_FILE=$1
        shift

        # Si el fichero no existe, se intenta crear uno con el formato adecuado
        # Si no se puede, termina con codigo de error
        if ! [[ -e "$CONFIG_FILE" ]]; then
            init_conf_file "$CONFIG_FILE"
            if [[ $? -ne 0 ]]; then
                return 3 # Error en la creacion del fichero
            fi
        fi

        # Comprobamos permisos del fichero; si no se puede escribir o leer, 
        # termina con error
        declare -i FIL_PERM=$(perm "$CONFIG_FILE") 
        if ! (( (( $FIL_PERM & $RW_PERM )) != 0 )); then
            return 3 # No podemos escribir o leer en el fichero
        fi

        # Si el fichero existe, pero no tiene el formato adecuado, se termina
        # con error. Si este script fuera interactivo, podriamos dar la opcion
        # de sobreescribir; seria facil realizar el cambio si se considera
        # oportuno.
        test_file_format "$CONFIG_FILE"
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
                    if [[ $2 =~ .*/?"$STATS_FILE_DEFAULT" ]]; then
                        # . no es un wildcard para el globbing, asi que
                        # cambiamos . por $PWD, pues necesitamos rutas absolutas
                        STATS_FILE=$(echo $2 | sed "s:\./\(.*\):$PWD/\1:")
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
            chlength "$CONFIG_FILE" "$LENGTH"
        fi

        if [[ -n "$STATS_FILE" ]]; then
            chpath "$CONFIG_FILE" "$STATS_FILE"
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
    echo '          Puede  realizar los cambios que desee.  Para terminar         '
    echo '          seleccione volver al menu principal.                          '
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
                

                chconf "$CONFIG_FILE_PATH" -l "$LENGTH"

                clprevln # Limpiamos lo escrito
                echo '              Cambio realizado con exito'

                continue
            ;;

            b)
                read -p '              Nuevo fichero de estadisticas: ' STATSFILE

                while ! [[ "$STATSFILE" =~ .*/?"$STATS_FILE_DEFAULT" ]]; do
                    
                    clprevln; clprevln # Necesitamos dos lineas

                    echo -n "      El nombre del fichero de configuracion debe ser: "
                    echo "'$STATS_FILE_DEFAULT'"
                    read -p '      Introduzca un fichero valido: ' STATSFILE
                done
                
                clprevln; clprevln # Limpiamos lo escrito y nos situamos
                echo

                chconf "$CONFIG_FILE_PATH" -s "$STATSFILE"

                clprevln # Limpiamos lo escrito
                echo '              Cambio realizado con exito'

                continue
            ;;
        
            c)
                NEW_LENGTH_G=$LENGTH
                NEW_STATS_FILE_G=$STATSFILE
                break
            ;;
        esac
    done

    return 0
}