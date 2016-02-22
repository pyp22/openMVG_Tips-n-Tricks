#!/bin/bash
#
# v1.1 2015,25,09 # compil in $home and get rid of sudo except for install
# author: py.paranthoen AT gmail YOU KNOW WHAT com
#
# This script, which somes has this, is available for Ubuntu distros and maybe for other ones using the apt-get mecanism.
#
# Its purpose is to automate openMVG AND openMVS compilation and installation under a Ubuntu distro.
#
# It's been realased as this and free to use, modify, copy and so on ...
# binaries & libs are installed in /usr/local and camera database in /usr/local/etc
#
# References:
# ------------------------------------------------------------
# openMVG authors & docs : https://github.com/openMVG/openMVG/
# ------------------------------------------------------------
# Pierre Moulon <pmoulon@gmail.com>
# Pascal Monasse <monasse@imagine.enpc.fr>
# Renaud Marlet <renaud.marlet@enpc.fr>
# anhtuann
# Bruno Duisit
# Fabien Castan
# Iivari ï¿½kï¿½
# luxigo
# Michael Holroyd
# Romain Janvier
# Rory McCann
# Romuald Perrot
# rhiestan
# sergi pujades-rocamora
# sflotron
# vincentweb
# Yohann Salaun
#
# ------------------------------------------------------------
# openMVS authors & docs : https://github.com/OpenMVS
# ------------------------------------------------------------
# cDc Seacave, Foxel and Pierre Moulon.


# get number of cpu cores to use
NBcore=$([[ $(uname) = 'Darwin' ]] &&
                       sysctl -n hw.logicalcpu_max ||
                       lscpu -p | egrep -v '^#' | wc -l)

# Directories settings
# Main Compilation Dir: prefer your user HomeDir
MainWorkDir=$PWD

##openMVG
openMVGSrcDir=$MainWorkDir/openMVG/src
openMVG_BuildDir=$openMVGSrcDir/build

##openMVS
openMVSSrcDir=$MainWorkDir/openMVS
openMVS_BuildDir=$openMVSSrcDir/build

##Ceres
CeresSrcDir=$MainWorkDir/ceres-solver
Ceres_BuildDir=$CeresSrcDir/build

##VCGLib
VCGLibSrcDir=$MainWorkDir/vcglib

if which sudo >/dev/null; then
    echo sudo installed, ok!
else
    echo sudo not there! Installing it!
    sudo apt-get install -qq -y sudo
fi

installDeps(){
echo
echo "Installing necessary dependencies..."
sudo apt-get install -qq -y apt-listchanges build-essential cmake git libpng12-dev libjpeg8-dev libxxf86vm1 libxxf86vm-dev libxi-dev libxrandr-dev
sudo apt-get install -qq -y python-sphinx freeglut3-dev zlib1g-dev libncurses5-dev glew-utils libdevil-dev libboost-all-dev libatlas-cpp-0.6-dev
sudo apt-get install -qq -y libatlas-dev libgsl0-dev liblapack-dev liblapack3 libpthread-workqueue-dev
sudo apt-get install -qq -y libpng-dev libtiff-dev libxxf86vm1 libxi-dev libxrandr-dev graphviz
sudo apt-get install -qq -y mesa-common-dev subversion libgoogle-glog-dev libatlas-base-dev libeigen3-dev libsuitesparse-dev
sudo apt-get install -qq -y libcgal-dev libopencv-dev libimage-exiftool-perl ImageMagick
}


clone-openMVG_GitHub(){
echo
echo "Cloning OpenMVG from Github..."
cd $MainWorkDir
git clone https://github.com/openMVG/openMVG.git
cd $openMVGSrcDir
#git checkout develop
git checkout master
git submodule init
git submodule update
cd ..
}

compile_openMVG(){
echo
echo "Compiling OpenMVG..."
echo

if [ -d $openMVG_BuildDir ] ; then
    echo "openMVG build dir OK!"
else
    echo "openMVG build dirNOK! creating it."
    mkdir -pv $openMVG_BuildDir
fi

cd $openMVG_BuildDir
cmake -DCMAKE_BUILD_TYPE=RELEASE -DOpenMVG_BUILD_TESTS=ON -DOpenMVG_BUILD_EXAMPLES=ON . $openMVGSrcDir
make -j$NBcore
}

install_openMVG(){
echo
echo "Installing OpenMVG..."
cd $openMVG_BuildDir
sudo make install
}

testOpenMVG(){
echo
echo "Testing..."
cd $openMVG_BuildDir
sudo make -j$NBcore test
}

clearSources(){
if [ -d $MainWorkDir/openMVG ] ; then
    echo
    echo "Removing previous openMVG source files ..."
    sudo rm -fr $MainWorkDir/openMVG
fi

if [ -d $MainWorkDir/openMVS ] ; then
    echo
    echo "Removing previous openMVS source files ..."
    sudo rm -fr $MainWorkDir/openMVS
fi

if [ -d $MainWorkDir/ceres-solver ] ; then
    echo
    echo "Removing previous ceres-solver source files ..."
    sudo rm -fr $MainWorkDir/ceres-solver
fi

if [ -d $MainWorkDir/vcglib ] ; then
    echo
    echo "Removing previous vcglib source files ..."
    sudo rm -fr $MainWorkDir/vcglib
fi
}

clone-Ceres_GitHub(){
echo
echo "Cloning Ceres from Github..."
cd $MainWorkDir
git clone https://ceres-solver.googlesource.com/ceres-solver
}

compil_Ceres(){
echo
echo "compiling Ceres ..."

if [ -d $Ceres_BuildDir ] ; then
    echo "Work dir OK!"
else
    echo "Work dir NOK! creating it."
    mkdir -pv $Ceres_BuildDir
fi


cd $Ceres_BuildDir
cmake . ..
}

install_Ceres(){
echo
echo "Installing Ceres ..."
cd $Ceres_BuildDir
make -j$NBcore
sudo make install
}

clone-vcglib_GitHub(){
echo
echo "Cloning vcglib from Github..."
cd $MainWorkDir
svn checkout svn://svn.code.sf.net/p/vcg/code/trunk/vcglib vcglib
cd $VCGLibSrcDir
patch -Np0 -i ../VCGLib.patch
}

clone-openMVS_GitHub(){
echo
echo "Cloning openMVS from Github..."
cd $MainWorkDir
git clone https://github.com/cdcseacave/openMVS.git
}

compile_openMVS(){

if [ -d $openMVS_BuildDir ] ; then
    echo "Work dir OK!"
else
    echo "Work dir NOK! creating it."
    mkdir -pv $openMVS_BuildDir
fi

echo
echo "Compiling OpenMVS..."
cd $openMVS_BuildDir
cmake -DCMAKE_BUILD_TYPE=RELEASE -DVCG_DIR="$VCGLibSrcDir" \
    -DCERES_DIR="/usr/local/share/Ceres" \
    -DOpenCV_CAN_BREAK_BINARY_COMPATIBILITY=OFF \
    -DOpenMVG_DIR:STRING="/usr/local/share/openMVG/cmake/" . ..
make -j$NBcore
}

install_openMVS(){
echo
echo "installing openMVS into /usr/local"
cd $openMVS_BuildDir/bin
sudo cp * /usr/local/bin
}

# Run fonctions. Comment or comment out to suit your needs.
installDeps
clearSources
clone-openMVG_GitHub
compile_openMVG
install_openMVG
testOpenMVG
clone-Ceres_GitHub
compil_Ceres
install_Ceres
clone-vcglib_GitHub
clone-openMVS_GitHub
compile_openMVS
install_openMVS

echo
echo "openMVG & openMVS should be avilable from /usr/local/{bin,lib}"






