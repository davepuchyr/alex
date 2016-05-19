#!/bin/bash
cd /home/dave/bld/gcc-412/netmorpher/release/firefox-1.5/dist/bin
rsync --exclude extensions/netmorpher@netmorphtech.com/tmp --exclude access\* --exclude error\* --exclude graph\*log --exclude morph\*js -avPz jazztel:`pwd`/. .

