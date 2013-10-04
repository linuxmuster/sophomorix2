#!/bin/bash

#
# schule +--- nur12 -------- klasse12c ------ 12c(adminclass)                 
#        |
#        |
#        +--- 10bis11 --+--- klasse11a ------ 11a(adminclass)
#                       |  
#                       |
#                       +--- klasse10c ------ 10c(adminclass)
#

sophomorix-project --create -p klasse7a --membergroups 7a
sophomorix-project --create -p klasse10c --membergroups 10c
sophomorix-project --create -p klasse11a --membergroups 11a
sophomorix-project --create -p klasse12c --membergroups 12c
sophomorix-project --create -p 10bis11 --memberprojects klasse10c,klasse11a
sophomorix-project --create -p nur12 --memberprojects klasse12c
sophomorix-project --create -p schule --memberprojects 10bis11,nur12 

 

