#!/bin/bash

#******************************************************************************#
#                                   group_if.sh                                #
#                                                                              #
# Muestra los miembros del grupo.                                              #
#                                                                              #
#******************************************************************************#

# Author: Samuel Gomez Sanchez
# Date: 02/11/17
# v1.0

# Usage:
#   group_if.sh
#
    # Exit status
    #
    #   0




# Variables

RELEASE_DATE=$(date +'%b-%Y')
VERSION='v1.0'

clear

echo
echo
echo
echo
echo
echo
echo
echo
echo
echo '                                Combinator                                '
echo '                          '"$VERSION"'              '"$RELEASE_DATE"'     '
echo
echo
echo
echo
echo '       Copyright Samuel Gómez Sánchez, Luis Blázquez Miñambres, '\
$(date +'%Y') '      '
echo '                            All Rights Reserved.                          '
echo
echo
echo
echo
echo
echo
read -n 1 -p 'Pulse cualquier tecla para volver al menu principal...' A

exit 0
