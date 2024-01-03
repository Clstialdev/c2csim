# Attention aux chemins absolus

Dans Main.qml : 
- source = "file://" + "/home/elias/TP_PROG/M1IM/Reseaux/c2csim/images/generated/car_modified_" + modelData.id + ".svg"


Dans la fonction applyColorToSVG() de SumoInterface.cpp:
- QString originalFilePath = "/home/elias/TP_PROG/M1IM/Reseaux/c2csim/images/car-cropped.svg";
- QString uniqueFileName = "/home/elias/TP_PROG/M1IM/Reseaux/c2csim/images/generated/car_modified_" + id + ".svg";


# Initialisation de l'environnement de travail

- Modifier #include "/home/user/TP_PROG/M1IM/Reseaux/c2csim/sumo-integrator-master/lib/sumo/libsumo.h" dans Sumo.h pour mettre votre chemin de libsumo.h  

- Pareil pour #include "/home/user/TP_PROG/M1IM/Reseaux/c2csim/sumo-integrator-master/lib/sumo/libsumo.h" dans compound.h, mettre votre chemin de libsumo.h  

- $ cmake -DCMAKE_PREFIX_PATH=/home/user/Qt/6.6.0/gcc_64/lib/cmake/Qt6 CMakeLists.txt   
Pour compiler, remplacer le chemin ci-dessus par votre chemin menant à Qt6  

- $ make  

- $ sumo-gui --remote-port 6066 -c ./sumofiles/osm.sumocfg  
  ou  
- $ make run  
Une fois l'exécutable généré, lancer une des 2 commandes ci-dessus

- $ ./appsumotest  
Lancer cette commande sur un autre terminal, en même temps que celle plus en haut

Cliquer sur le bouton Play/Run de Sumo pour lancer la simulation.  
Changement de port possible en modifiant la valeur dans SumoInterface.cpp

## Commandes ajoutées au Makefile

#### Run
run:  
&nbsp; &nbsp; &nbsp; &nbsp;sumo-gui --remote-port 6066 -c "./sumofiles/osm.sumocfg"  
.PHONY : run  

#### Restart (permet de ne pas avoir à retaper les autres commandes à chaque exécution)
restart: clean all run
