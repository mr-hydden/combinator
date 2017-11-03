#!/bin/bash

# Usage:
#   config.sh [-l newlength | -s path/to/stats/file]
#
# RETURN VALUES
#   0 si tiene exito
#   

# Constantes
CONFIG_FILE='conf.cfg'
CONFIG_FILE_PATH=$PWD
STATS_FILE='estadisticas.txt'
declare -i N_PERM=2#000    # ---
declare -i R_PERM=2#100    # r--
declare -i W_PERM=2#010    # -w-
declare -i X_PERM=2#001    # --x
declare -i RW_PERM=2#110   # rw-
declare -i WX_PERM=2#011   # -wx
declare -i RX_PERM=2#101   # r-x
declare -i RWX_PERM=2#111  # rwx

# Variables de entrada
NEW_STATS_FILE=
NEW_LENGTH=




# ***********************************************
# binpermf                                      *
# ***********************************************
# Convierte una cadena de permisos en un numero *
# binario que devuelve
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
# testperm                                      *
# ***********************************************
# Comprueba los permisos del fichero o          *
# o directorio $1                               *
#                                               *
            function testperm() {                         
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

        if ! [[ -e "$FILE" ]]; then
            echo 8 # 2#1000, valor invalido; fichero no existe
            return 2
        fi


        if [ -r "$FILE" ]; then
            # Los permisos hay que ponerlos negados porque indican que permisos
            (( PERMISSIONS += $R_PERM )) # Incluimos permiso r--
        fi
        if [ -w "$FILE" ]; then
            (( PERMISSIONS += $W_PERM )) # Incluimos permiso -w-
        fi
        if [ -x "$FILE" ]; then
            (( PERMISSIONS += $X_PERM )) # Incluimos permiso --x
        fi

        echo $PERMISSIONS
        return 0

    else
        echo 8 # 2#1000, valor invalido; formato de argumentos erroneo
        return 1
    fi
}



# ***********************************************
# init_conf_file                                *
# ***********************************************
# Crea el fichero de configuracion con nombre   *
# con nombre $1 en el directorio de ruta $2     *
#                                               *
            function init_conf_file() {                         
# **********************************************
#
    # Return:
    #   0 si tiene exito
    #
    #   1 si recibe argumentos erroneos
    #
    #   2 si no se pudo crear el fichero o directorio
    #
    #   3 si no se tiene permisos de lectura y escritura en el directorio $2
    #   es decir, no se puede escribir en el fichero, leerlo, etc.
    #
    #   Codigo de permiso: R_PERM, W_PERM o RW_PERM si falta alguno para el 
    #                      fichero

    local DIR=
    local CONFIG_FILE=

    if [ $# -eq 2 ]; then

        CONFIG_FILE=$1
        DIR=$2

        if ! [[ -e "$DIR" ]]; then
            mkdir "$DIR"
            if (( $? != 0 )); then  # Si el directorio no se creo correctamente
                return 2            # (porque no hay permisos, e.g.)
            fi
        fi
        
        declare -i DIR_PERM=`testperm "$DIR"`
        if (( $DIR_PERM == $RWX_PERM )); then

            cd "$DIR"

            if ! [ -e "$CONFIG_FILE" ]; then
                touch "$CONFIG_FILE"
                if (( $? != 0 )); then # Si el fichero no se creo correctamente
                      return 2
                fi
            fi

            local FIL_PERM=$(testperm "$CONFIG_FILE") # En principio
                                                      # no hace falta comprobar
                                                      # el valor de retorno,
                                                      # es mas una medida de 
                                                      # seguridad, o en caso
                                                      # de necesitar debugging
                
            # Comprobamos cuales son los permisos recibidos de testperm
            # haciendo AND a nivel de bit con el resultado. Como la mascara
            # que pasamos es 110, si se apaga alguno de los bits mas
            # significativos, es que falta algun permiso.
            # Tenemos que hacerlo porque no conocemos el umask del sistema
            # y parsearlo sería más o menos igual de costoso

            declare -i UMASK=$RW_PERM   # Necesitamos los mismos permisos 
                                        # para leer y editar el fichero

            if (( (( $FIL_PERM & $UMASK )) == $W_PERM )); then
                return $R_PERM # Faltan permisos de lectura
            fi
            if (( (( $FIL_PERM & $UMASK )) == $R_PERM )); then
                return $W_PERM # Faltan permisos de escritura
            fi
            if (( (( $FIL_PERM & $UMASK )) == $N_PERM )); then
                return $RW_PERM # No hay permisos de lectura ni de escritura
            fi
            
            # Escribimos el fichero en el formato adecuado
            echo 'LONGITUD=0' | cat > "$CONFIG_FILE"
            echo "ESTADISTICAS=$PWD/estadisticas.txt" | cat >> "$CONFIG_FILE"

            return 0

        else
            return 3 # No hay permisos en el directorio
        fi
    else
        return 1 # Argumentos erroneos en numero
    fi
}



# ***********************************************
# changePath()                                  *
# ***********************************************
# Funcion que modifica la ruta al fichero de    *
# estadisticas en el fichero de configuracion   *
#                                               *
            function changePath() {                         
# ***********************************************

    # Requiere 2 argumentos obligatorios: una ruta a un fichero y una cadena
    # Uso: changePath FILE STRING
    # Cambia el fichero FILE, que tiene el siguiente formato
    #
    # File structure
    #==============================================================
    #LONGITUD=N
    #ESTADISTICAS=/path/to/statistics/file
    #^D 
    #==============================================================
    #
    # /path/to/statistics/file se cambiara por STRING
    #
    # Esta funcion espera un fichero con permisos de escritura y lectura. 
    # No comprueba la validez de la nueva ruta STRING
    #
    # Return values:
    #   0 si tiene exito
    #
    #   1 si los argumentos son invalidos (en numero)
    #
    #   3 si el fichero de configuracion no existe y no se puede crear

    local CONFIG_FILE=
    local NEW_STATS_FILE=

    if [ $# -eq 2 ]; then

        CONFIG_FILE=$1
        NEW_STATS_FILE=$2

        # ESTO PARA EL MODULO SUPERIOR ------------------------------------------------------------------

        # Separamos la ruta y el nombre del fichero, para poder trabajar con
        # testperm y comprobar los permisos por separado
        CONFIG_FILE_PATH=`echo $CONFIG_FILE | sed -n 's:\(.*\)/.*$:\1:p'`
        CONFIG_FILE_NAME=`echo $CONFIG_FILE | sed -n 's:.*/\(.*\)$:\1:p'`
    
        local DIR_PERM=`testperm "$CONFIG_FILE_PATH"`
        declare -i local UMASK=2#110    # To test if we have read and write permissions,
                                        # which we need. If DIR_PERM & UMASK != 110, 
                                        # one or both of those is 0

        if (( (( $DIR_PERM & $UMASK )) == 2#010 )); then
            return $R_PERM
        fi
        if (( (( $DIR_PERM & $UMASK )) == 2#100 )); then
            return $W_PERM
        fi
        if (( (( $DIR_PERM & $UMASK )) == 2#000 )); then
            return $RW_PERM
        fi
        
        if [[ ! -e "$CONFIG_FILE_PATH"/"$CONFIG_FILE_NAME" ]]; then
            if ! init_conf_file "$CONFIG_FILE_NAME" "$CONFIG_FILE_PATH"
            then
                return 2 # Fichero de configuracion no se puede crear
            fi
        fi
        # ----------------------------------------------------------------------------------------------

        sed -i "2s:ESTADISTICAS=.*:ESTADISTICAS=$NEW_STATS_FILE:" \
        "$CONFIG_FILE_PATH"/"$CONFIG_FILE_NAME"

        return 0

    else
        return 1 # Numero de argumentos no valido
    fi
}



# ***********************************************
# changeLength()                                *
# ***********************************************
# Funcion que modifica la longitud por defecto  *
# en el fichero de configuracion                *
#                                               *
            function changeLength() {                         
# ***********************************************

    # Requiere 2 argumentos obligatorios: una ruta a un fichero y un entero N
    # Uso: changePath FILE N
    # Cambia el fichero FILE, que tiene el siguiente formato
    #
    # File structure
    #==============================================================
    #LONGITUD=K
    #ESTADISTICAS=/path/to/statistics/file
    #^D 
    #==============================================================
    #
    # K se cambia por N
    #
    # Esta funcion espera un fichero con permisos de escritura y lectura. 
    # Si N no es un numero entero, devuelve error y no cambia nada.
    #
    # Return values:
    #   0 si tiene exito
    #
    #   1 si los argumentos son invalidos (en numero)
    #
    #   3 si el fichero de configuracion no existe y no se puede crear

    local CONFIG_FILE=
    local NEW_LENGTH=

    if [ $# -eq 2 ]; then

        CONFIG_FILE=$1
        if [[ $2 =~ [0-9] ]]; then
            NEW_LENGTH=$2
        else
            return 1
        fi

        # ESTO PARA EL MODULO SUPERIOR ---------------------------------------------------------------

        # Separamos la ruta y el nombre del fichero, para poder trabajar con
        # testperm y comprobar los permisos por separado
        CONFIG_FILE_PATH=`echo $CONFIG_FILE | sed -n 's:\(.*\)/.*$:\1:p'`
        CONFIG_FILE_NAME=`echo $CONFIG_FILE | sed -n 's:.*/\(.*\)$:\1:p'`
    
        local DIR_PERM=`testperm "$CONFIG_FILE_PATH"`
        declare -i local UMASK=2#110    # To test if we have read and write permissions,
                                        # which we need. If DIR_PERM & UMASK != 110, 
                                        # one or both of those is 0

        if (( (( $DIR_PERM & $UMASK )) == 2#010 )); then
            return $R_PERM
        fi
        if (( (( $DIR_PERM & $UMASK )) == 2#100 )); then
            return $W_PERM
        fi
        if (( (( $DIR_PERM & $UMASK )) == 2#000 )); then
            return $RW_PERM
        fi
        
        if [[ ! -e "$CONFIG_FILE_PATH"/"$CONFIG_FILE_NAME" ]]; then
            if ! init_conf_file "$CONFIG_FILE_NAME" "$CONFIG_FILE_PATH"
            then
                return 2 # Fichero de configuracion no se puede crear
            fi
        fi
        
        # -----------------------------------------------------------------------------------------------
      
        sed -i "s:LONGITUD=.*:LONGITUD=$NEW_LENGTH:" \
        "$CONFIG_FILE_PATH"/"$CONFIG_FILE_NAME"

        return 0

    else
        return 1 # Numero de argumentos no valido
    fi
}


# *********************************************** # Este es el hipotetico modulo superior, debera llamar a changeLength
# changeConfig()                                * # o changePath segun proceda y pasarles argumentos comprobados
# ***********************************************
# Function to change length in config file      *
#                                               *
            function changeConfig() {                         
# ***********************************************
