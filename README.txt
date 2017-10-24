README.txt
v1.0

PROJECT DIAGRAM (MODIFICATION SUGGESTIONS AVAILABLE)
----------------------------------------------------

La organizacion del proyecto puede ser como sigue:


combinator (conf.cfg, estadisticas.txt, statsCalculatedFile)
    |               
    |---------------|- User interface
                    |       |           
                    |       |-----------|- Show info + prompt   (1)
                    |                   |- Game over            (2)
                    |                   |- Config info          (3)
                    |                   |- Stats info           (4)
                    |                   |- Group info           (5)
                    |
                    |
                    |
                    |- Controller
                            |
                            |- Data (non-volatile)              
                            |       |
                            |       |- Update stats             (6)
                            |       |- Modify config            (7)
                            |
                            |
                            |- Game (dynamic)
                                    |
                                    |- Setup                    (8)
                                    |- Info updating            (9)



(1): Durante del desarrollo de la opcion "Juego", el bucle principal
consiste en enseñar información, recogerla y actualizar. Este primer
punto se encarga de enseñarla.
(2): Cuando la opcion "Juego" finaliza (juego resuelto) actúa este
módulo.
(3): Interfaz de usuario de la opción "Configuración"
(4): Interfaz de usuario de la opción "Estadísticas"
(5): Muestra el nombre de los componentes del grupo
(6): Se encarga de actualizar el fichero "estadisticas.txt" así como
de recalcular las estadísticas en "statsCalculatedFile" (nombre pro_
visional). Este último contiene el número total de partidas jugadas,
datos de la partida más corta, etc.
(7): Módulo que se encarga de actualizar el fichero "conf.cfg"
(8): Setup genera la contraseña de la caja fuerte, y pone a punto
el entorno al comienzo del juego.
(9): Actualización de la información del juego en cada turno.


EXECUTION BLUEPRINT (ESTIMATED)
-------------------------------

Pseudocódigo aproximado:


        PROCEDURE combinator
            showMenu
            get(option)
            SWITCH(option)

                CASE juego
                    setup()

                    WHILE (GameNotBeaten)
                        show(info, prompt)
                        update(info)
                    END_WHILE

                    showEndMessage()
                    update(estadisticas.txt, statsCalculatedFile)
                    backToMenu()

                END_CASE_juego

                CASE configuracion
                    showUserInterface()
                    modifyFile(conf.cfg)
                    backToMenu()
                END_CASE_configuracion

                CASE estadisticas
                    showStatsInfo()
                    backToMenu()
                END_CASE_estadisticas

                CASE grupo
                    showGroupNames()
                    backToMenu()
                END_CASE_grupo

                CASE salir
                    optionalGoodbyeMessage()
                END_CASE_salir

            END_SWITCH

        END_PROCEDURE_combinator



























