# ***********************************************
# test_file_format                              *
# ***********************************************
# Comprueba que el formato del fichero  de      *
# configuracion es el adecuado                  *
#                                               *
            function test_file_format() {                         
# **********************************************

    if (( $# == 1 )); then
        declare -i local LINENO
        LINENO=$(cat $1 2> /dev/null | wc -l)
        if (( $LINENO == 2 )); then
            # Lo siguiente seria mejor con patrones multilinea, pero
            # no se usarlos con sed, y no me quiero arriesgar a que 
            # pcregrep no funcione sobre encina.fis.usal.es
            
            head -n 1 $1 | grep '^LONGITUD=[0-9]$' &> /dev/null
            local BAD_FORMAT_LINE1=$?
            tail -n 1 $1 | grep '^ESTADISTICAS=.*$' &> /dev/null
            local BAD_FORMAT_LINE2=$?

            if (( $BAD_FORMAT_LINE1 != 0 || $BAD_FORMAT_LINE2 != 0 )); then
                return 1 # Formato de las lineas incorrecto
            fi

            return 0 # Formato correcto

        else
            return 1 # Numero de lineas incorrecto
        fi
    else
        return 1
    fi

}
