#! /usr/bin/env bash

mkdir quake106_temp
cd quake106_temp

figlet wget
wget https://ftp.gwdg.de/pub/misc/ftp.idsoftware.com/idstuff/quake/quake106.zip

figlet unzip
unzip quake106.zip

figlet lha
lha x resource.1

figlet copy id1
mkdir -p ../../id1
cp -v id1/pak0.pak ../../id1

cd ..

figlet clean up
rm -Rfv quake106_temp/
