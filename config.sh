#!/bin/bash

# Usage:
#   configuration.sh [-l newlength | -s path/to/stats/file]
#
# RETURN VALUES
#   0   Success
#   1   Wrong arguments' format
#   114 Lacking read permissions. 114 = r (ASCII)
#   119 Lacking write permissions. 119 = w (ASCII)
#   120 Lacking execution permissions. 120 = x (ASCII)
#   

# Constants
CONFIG_FILE='conf.cfg'
CONFIG_FILE_PATH=$PWD
STATS_FILE='estadisticas.txt'
R_PERM=114 # r = 114 ASCII
W_PERM=119 # r = 119 ASCII
X_PERM=120 # r = 120 ASCII
RW_PERM=$(( $R_PERM ^ $W_PERM )) # r XOR w = 0x04
RX_PERM=$(( $R_PERM ^ $X_PERM )) # r XOR x = 0xf2
WX_PERM=$(( $W_PERM ^ $X_PERM )) # w XOR x = 0xf7
RWX_PERM=$(( $R_PERM ^ $W_PERM ^ $X_PERM )) # r XOR w XOR x = 0x7d

# Input variables
NEW_STATS_FILE=
NEW_LENGTH=





# ***********************************************
# testperm                                      *
# ***********************************************
# Tests permissions of $1                       *
#                                               *
            function testperm() {                         
# ***********************************************
    #
    # Return: 
    #   0 on success
    #   1 if error (file not existent, can't read on PWD or no arguments)
    #
    # Echoes a number corresponding to permission change for
    # current user, for example 6 means rw-
    #

    if [ $# -eq 1 ]; then
    
        local FILE=$1
        local PERMISSIONS=0

        if ! [[ -r "$PWD" && -e "$FILE" ]]; then
            return 1
        fi


        if [ -r "$FILE" ]; then
            (( PERMISSIONS += 2#100 )) # Add r-- to permissions
        fi
        if [ -w "$FILE" ]; then
            (( PERMISSIONS += 2#010 )) # Add -w- to permissions
        fi
        if [ -x "$FILE" ]; then
            (( PERMISSIONS += 2#001 )) # Add --x to permissions
        fi

        echo $PERMISSIONS
        return 0
    else
        return 1
    fi
}



# ***********************************************
# init_conf_file                                *
# ***********************************************
# Creates default conf.cfg file on $1           *
#                                               *
            function init_conf_file() {                         
# **********************************************
    local DIR=
    local CONFIG_FILE=

    if [ $# -eq 2 ]; then
        DIR=$1
        CONFIG_FILE=$2
        if [[ -d "$DIR" && -w "$DIR" && -r "$DIR" ]]; then

            touch "$DIR"/"$CONFIG_FILE"

            # The following is ugly, but testperm can't be done on a file
            # before knowing if we can read the folder that contains it
            # or whether it exists.
            # We must check permissions because we don't know the
            # system's umask; checking it is approximately as costly
            # as checking this
            local FIL_PERM=$(testperm "$CONFIG_FILE")
            UMASK=2#110 # Same permissions needed

            if (( (( $FIL_PERM & $UMASK )) == 2#010 )); then
                echo $R_PERM
                return 1
            fi
            if (( (( $FIL_PERM & $UMASK )) == 2#100 )); then
                echo $W_PERM
                return 1
            fi
            if (( (( $FIL_PERM & $UMASK )) == 2#000 )); then
                echo $RW_PERM
                return 1
            fi

            echo 'LONGITUD=0' | cat > "$CONFIG_FILE"
            echo "ESTADISTICAS=$PWD/$STATS_FILE" | cat >> "$CONFIG_FILE"

            return 0

        else
            return 1
        fi
    else
        return 1
    fi
}



# ***********************************************
# changePath()                                  *
# ***********************************************
# Function to change path in configuration file *
#                                               *
            function changePath() {                         
# ***********************************************

    # Needs 2 mandatory arguments: a path to a file and a string
    # Usage: changePath PATH STRING
    # Changes the configuration file FILE, which has a format as follows:
    #
    # File structure
    #==============================================================
    #LONGITUD=N
    #ESTADISTICAS=/path/to/statistics/file
    #^D 
    #==============================================================
    #
    # /path/to/statistics/file will become STRING
    #
    # This function testes if configuration file exists, and creates it
    # if it does not. However, it does not check validity of STRING
    #
    # Return values:
    #
    #

    local CONFIG_FILE_PATH=
    local NEW_STATS_FILE=

    if [ $# -e 2 ]; then

        CONFIG_FILE_PATH=$1     # These are the local variables
        NEW_STATS_FILE=$2  #
    
        local DIR_PERM=$(testperm "$CONFIG_FILE_PATH")
        local UMASK=2#110   # To test if we have read and write permissions,
                            # which we need. If DIR_PERM & UMASK != 110, 
                            # one or both of those is 0

        if (( (( $DIR_PERM & $UMASK )) == 2#010 )); then
            echo $R_PERM
            return 1
        fi
        if (( (( $DIR_PERM & $UMASK )) == 2#100 )); then
            echo $W_PERM
            return 1
        fi
        if (( (( $DIR_PERM & $UMASK )) == 2#000 )); then
            echo $RW_PERM
            return 1
        fi
        
        if [[ ! -e "$CONFIG_FILE_PATH"/"$CONFIG_FILE" ]]; then
            if ! init_conf_file "$CONFIG_FILE_PATH" "$CONFIG_FILE"; then
                return 1
            fi
        fi

        sed -i "2s:ESTADISTICAS=.*:ESTADISTICAS=$NEW_STATS_FILE" \
        "$CONFIG_FILE_PATH"/"$CONFIG_FILE"
    else
        return 1
    fi
}





# FROM HERE TO END NOT TESTED. UPPER FUNCTIONS ARE WORKING AND TESTED.
while :
do
    case $1 in
        -l | --length) # To change length
            if [[ $2 =~ [0-9] ]]; then
                NEW_LENGTH=$2
                shift 2
            else
                echo "config: invalid argument '$2' for option '$1'" >&2
                exit 1
            fi
            ;;
        
        -s | --statsfile) # To change statistics file
            if [[ $2 =~ .*/"$STATS_FILE" ]]; then
                NEW_STATS_FILE=$2
                shift 2
            else
                echo "config: invalid argument '$2' for option '$1'" >&2
                echo "config: statistics file must be named '$STATS_FILE'"
                exit 1
            fi
            ;;

        -*)
            echo "config: invalid option '$1'" >&2
            echo "Usage: config [-l | --length N] [-s | --statsfile FILE]" >&2
            echo "Try 'config --help' for more information" >&2
            exit 1
            ;;
        *)
            break
            ;;
    esac
done






if [ -n "$NEW_STATS_FILE" -a -n "$NEW_LENGTH" ]; then
        # CHANGE PATH AND LENGHT
else

    if [ -n "$NEW_LENGTH" ]; then
        # CHANGE LENGTH
    fi
    if [ -n "$NEW_STATS_FILE" -a -n "$NEW_LENGTH" ]; then
        # CHANGE PATH
    fi
fi
