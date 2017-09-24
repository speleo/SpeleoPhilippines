This repoistory holds the data and survey working files for caves explored by the Speleo Philippines Expeditions.

Copyright - all the data except the photos is Creative Commons Share Alike

Surveys have been created using Therion caving mapping software.  Therion is an free and open-source cave surveying software, designed to process survey data; generate maps and 3D models of caves; and archive the data describing the cave and the history of exploration.  It is available from https://therion.speleo.sk/

To make the data portable relative paths have been used.
Complile will fail unless you declare the root source in the texmf.cnf file which is located in \therion\texmf\web2c folder

I've used this 

TEXINPUTS = $TEXMF/tex;C:/Users/henry_bennett/Documents/GitHub/SpeleoPhilippines/;.
MPINPUTS = C:/Users/henry_bennett/Documents/GitHub/SpeleoPhilippines/;.


you will need to change this to your source paths.

note
----
you may find that you are unable to save this file unless you edit it as the host administrator.  To do this open a command prompt as an administrator and then edit the file directly from there.