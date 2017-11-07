#!/bin/bash

#******************************************************************************#
#                                   chconf.sh                                  #
#                                                                              #
# Modifica el fichero de configuracion, cambiando la longitud por defecto, el  #
# fichero de estadisticas por defecto o ambos.                                 #
#                                                                              #
#******************************************************************************#

# Author: Samuel Gomez Sanchez
# Date: 07/11/17
# v2.1

# Usage:
#   chconf.sh CONFIGURATION_FILE [-l newlength | -s path/to/stats/file]
#
    # Exit status
    #
    #   0 si tiene exito
    #
    #   1 formato de argumentos incorrecto
    #
    #   2 opcion invalida
    #
    #   3 error con el fichero (no existe y no se puede crear)
    #
    #   4 formato de fichero incorrecto  



# Constantes

CONFIG_FILE_GLOBAL='conf.cfg'
CONFIG_FILE_PATH_GLOBAL=$PWD
STATS_FILE_GLOBAL='estadisticas.txt'
STATS_FILE_PATH_GLOBAL=$PWD
declare -i N_PERM=2#000    # ---
declare -i R_PERM=2#100    # r--
declare -i W_PERM=2#010    # -w-
declare -i X_PERM=2#001    # --x
declare -i RW_PERM=2#110   # rw-
declare -i WX_PERM=2#011   # -wx
declare -i RX_PERM=2#101   # r-x
declare -i RWX_PERM=2#111  # rwx




#******************************************************************************#
#                                   FUNCIONES                                  #
#******************************************************************************#
#                                   binpermf                                   #
#                                   perm                                       #
#                                   test_file_format                           #
#                                   init_conf_file                             #
#                                   chpath                                     #
#                                   chlength                                   #
#******************************************************************************#


# ***********************************************
# binpermf                                      *
# ***********************************************
# Convierte una cadena de permisos en un numero *
# binario que devuelve                          *
#                                               *
            function binpermf() {                         
# ***********************************************
    #
    # Return:
    #   0 si tiene exito
    #   8 si el formato de argumentos es incorrecto
    #   9 si la cadena de permisos no es viable
    #
    
    if [ $# -eq 1 ]; then
        case $1 in
            'rwx' )
                return $RWX_PERM
                ;;
            'rw-' ) 
                return $RW_PERM
                ;;
            'r-x' )
                return $RX_PERM
                ;;
            'r--' )
                return $R_PERM
                ;;
            '-wx' )
                return $WX_PERM
                ;;
            '-w-' )
                return $W_PERM
                ;;
            '--x' )
                return $X_PERM
                ;;
            '---' )
                return $N_PERM
                ;;
            * )
                return 9 # Cadena de permisos inexistente
                ;;
        esac

    else
        return 8 # Formato de argumentos incorrecto
    fi
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
            
            head -n 1 $1 | grep '^LONGITUD=[0-9]$' &> /dev/null
            local BAD_FORMAT_LINE1=$?
            tail -n 1 $1 | grep '^ESTADISTICAS=.*$' &> /dev/null
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
        # lo crea en el directorio $CONFIG_FILE_PATH_GLOBAL
        if [[ -z "$CONFIG_FILE_NAME" || -z "$CONFIG_FILE_PATH " ]];then
            CONFIG_FILE_NAME=$CONFIG_FILE
            CONFIG_FILE_PATH=$CONFIG_FILE_PATH_GLOBAL
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
                touch "$CONFIG_FILE_NAME"   # Como tenemos permisos W, se crea sin
                                            # problema
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
                echo "ESTADISTICAS=$STATS_FILE_PATH_GLOBAL/estadisticas.txt" |\
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
#        local CONFIG_FILE_PATH=$(echo $CONFIG_FILE | sed -n 's:\(.*\)/.*$:\1:p')
#        local CONFIG_FILE_NAME=$(echo $CONFIG_FILE | sed -n 's:.*/\(.*\)$:\1:p')

        
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

        sed -i "s:ESTADISTICAS=.*:ESTADISTICAS=$NEW_STATS_FILE:" "$CONFIG_FILE"\
        &> /dev/null
        
        return $? # Si hay algun problema, diferente de 0. Si no, devuelve 0

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
#        local CONFIG_FILE_PATH=$(echo $CONFIG_FILE | sed -n 's:\(.*\)/.*$:\1:p')
#        local CONFIG_FILE_NAME=$(echo $CONFIG_FILE | sed -n 's:.*/\(.*\)$:\1:p')

        
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

        sed -i "s:LONGITUD=.*:LONGITUD=$NEW_LENGTH:" "$CONFIG_FILE"\
        &> /dev/null
        
        return $? # Si hay algun problema, diferente de 0. Si no, devuelve 0

    else
        return 1 # Numero de argumentos no valido
    fi
}


#******************************************************************************#
#                               PROGRAMA PRINCIPAL                             #
#                                   chconf.sh                                  #
#******************************************************************************#

    # Exit status:
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
        
CONFIG_FILE=
LENGTH=
STATS_FILE=

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
            exit 3 # Error en la creacion del fichero
        fi
    fi

    # Comprobamos permisos del fichero; si no se puede escribir o leer, 
    # termina con error
    declare -i FIL_PERM=$(perm "$CONFIG_FILE") 
    if ! (( (( $FIL_PERM & $RW_PERM )) != 0 )); then
        exit 3 # No podemos escribir o leer en el fichero
    fi

    # Si el fichero existe, pero no tiene el formato adecuado, se termina
    # con error. Si este script fuera interactivo, podriamos dar la opcion
    # de sobreescribir; seria facil realizar el cambio si se considera
    # oportuno.
    test_file_format "$CONFIG_FILE"
    if (( $? != 0 )); then
        exit 4 # Formato de fichero incorrecto
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
                    exit 1 # Error de formato de argumentos
                fi
            ;;
            
            -s | --statsfile)
                if [[ $2 =~ .*/"$STATS_FILE_GLOBAL" ]]; then
                    # . no es un wildcard para el globbing, asi que
                    # cambiamos . por $PWD, pues necesitamos rutas absolutas
                    STATS_FILE=$(echo $2 | sed "s:\./\(.*\):$PWD/\1:")
                    shift 2
                else
                    exit 1 # Error de formato de argumentos
                fi
            ;;

            -*)
                exit 2 # Opcion inexistente
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
        exit 1 # Argumentos erroneos
    fi

    # En otro caso, todo esta bien, se hacen los cambios pertinentes
    if [[ -n "$LENGTH" ]]; then
        chlength "$CONFIG_FILE" "$LENGTH"
    fi

    if [[ -n "$STATS_FILE" ]]; then
        chpath "$CONFIG_FILE" "$STATS_FILE"
    fi

    exit 0

else
    exit 1 # Numero de argumentos invalido
fi
