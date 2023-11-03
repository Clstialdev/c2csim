# Initialisation de l'environnement de travail

- Modifier "set(BASE_PATH "/home/user/TP_PROG/M1IM/Reseaux/c2csim")" dans CMakeLists.txt pour y mettre votre chemin du projet  

- Modifier #include "/home/user/TP_PROG/M1IM/Reseaux/c2csim/sumo-integrator-master/lib/sumo/libsumo.h" dans Sumo.h pour mettre votre chemin de libsumo.h  

- Pareil pour #include "/home/user/TP_PROG/M1IM/Reseaux/c2csim/sumo-integrator-master/lib/sumo/libsumo.h" dans compound.h, mettre votre chemin de libsumo.h  

- $ cmake -DCMAKE_PREFIX_PATH=/home/user/Qt/6.6.0/gcc_64/lib/cmake/Qt6 CMakeLists.txt   
Pour compiler, remplacer le chemin ci-dessus par votre chemin menant à Qt6  

- $ make  

- $  sumo-gui --remote-port 6066 -c ./sumofiles/osm.sumocfg   
Une fois l'exécutable généré, lancer la commande ci-dessus  
- $ ./appsumotest  
Lancer cette commande sur un autre terminal, en même temps que celle plus en haut  