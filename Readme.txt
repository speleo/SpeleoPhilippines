This repoistory holds the data and survey working files for caves explored by the Speleo Philippines Expeditions.

Copyright
---------- 
All the data except the photos is Creative Commons Share Alike

Data Format
-----------
Unless noted otherwise all data was collected with DistoX2 with PocketTopo.  Raw data was converted to Therion using Andrew Akinson's TopParser https://bitbucket.org/AndrewA/topparser/downloads/

Surveys have been created using Therion caving mapping software.  Therion is an free and open-source cave surveying software, designed to process survey data; generate maps and 3D models of caves; and archive the data describing the cave and the history of exploration.  It is available from https://therion.speleo.sk/

Therion modifications
---------------------
To make the data portable relative paths have been used.
Complile will fail unless you declare the root source in the texmf.cnf file which is located in \therion\texmf\web2c folder

I've used this 

   TEXINPUTS = $TEXMF/tex;C:/Users/henry_bennett/Documents/GitHub/SpeleoPhilippines/;.
   MPINPUTS = C:/Users/henry_bennett/Documents/GitHub/SpeleoPhilippines/;.

you will need to change this to your source paths.

You may find that you are unable to save the texmf.cnf file unless you edit it as the host administrator.  To do this open a command prompt as an administrator and then edit the file directly from there.

All I want is the Survey Output
-------------------------------
If you are just looking for the survey output you will find it in "output" folders.  Simply navigate the tree to where you want to go and look for the pdf files.  Some surveys have multiple outputs.  Refer to the Therion thbook for what this means and how to view them.