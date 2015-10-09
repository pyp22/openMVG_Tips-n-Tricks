#!/bin/bash
#
# v1 2014,08,30
# v0 from Natanael1234
# 
# This script is available for Debian distros and maybe for other ones using the aptitude mecanism (tested on Debian only)
#
# Its purpose is to automate openMVG compilation and installation under a Debian like distro.
#
# realased as this and free to use, modify, copy and so on ...
#
# binaries are installed in /usr/local/bin and camera databse in /usr/local/etc
#
# ToDo 
# add CMVS/PMVS automation
#
# Adjustement in OpenGL might be necessary regarding your graphic card. Add or modify it in installDeps (e.g. Nvdia)
#
#
#
# get number of cpu cores to use
NBcore=$([[ $(uname) = 'Darwin' ]] && 
                       sysctl -n hw.logicalcpu_max || 
                       lscpu -p | egrep -v '^#' | wc -l)
#
MainWorkDir=/usr/local/src
openMVGSrcDir=$MainWorkDir/openMVG/src
openMVG_BuildDir=$openMVGSrcDir/build

if which sudo >/dev/null; then
    echo sudo installed, ok!
else
    echo sudo not there! Installing it!
    apt-get install -qq -y sudo
fi

if [ -d $MainWorkDir ]; then
    echo working directory exists, ok!
else
    echo working directory does not, creating it!
    mkdir -p $openMVG_BuildDir
fi


installDeps(){
echo
echo "Installing necessary dependencies..."
sudo apt-get install -qq -y apt-listchanges build-essential cmake git libpng12-dev libjpeg8-dev libxxf86vm1 libxxf86vm-dev libxi-dev libxrandr-dev
sudo apt-get install -qq -y python-sphinx freeglut3-dev zlib1g-dev libncurses5-dev glew-utils libdevil-dev libboost-all-dev libatlas-cpp-0.6-dev 
sudo apt-get install -qq -y libatlas-dev libgsl0-dev liblapack-dev liblapack3 libpthread-workqueue-dev
}
 
 
cloneGitHub(){
echo
echo "Cloning OpenMVG from Github..."
cd $MainWorkDir
git clone https://github.com/openMVG/openMVG.git
cd $MainWorkDir/openMVG
git checkout develop
git submodule init
git submodule update
cd ..
}
 
compileAndInstallOpenMVG(){
echo
echo "Compiling OpenMVG..."
echo
mkdir $openMVG_BuildDir
cd $openMVG_BuildDir
 
cmake -DCMAKE_BUILD_TYPE=RELEASE -DOpenMVG_BUILD_TESTS=ON -DOpenMVG_BUILD_EXAMPLES=ON . $openMVGSrcDir
make -j $NBcore


# Install main binaries in /usr/local/bin
find $openMVG_BuildDir/software/SfM -type f -executable -exec cp {} /usr/local/bin \;
find $openMVG_BuildDir/software/globalSfM -type f -executable -exec cp {} /usr/local/bin \;
find $openMVG_BuildDir/software/colorHarmonize -type f -executable -exec cp {} /usr/local/bin \;
find $openMVG_BuildDir/software/SfMViewer -type f -executable -exec cp {} /usr/local/bin \;

#/usr/local/src/openMVG/src/build/software/globalSfM

# Install camera database in /usr/local/etc
cp $MainWorkDir/openMVG/src/software/SfM/cameraSensorWidth/cameraGenerated.txt /usr/local/etc

# Install samples binaries in /usr/local/bin
find $openMVG_BuildDir/openMVG_Samples -type f -executable -exec cp {} /usr/local/bin \;
}

testOpenMVG(){
echo
echo "Testing..."
cd $openMVG_BuildDir
make test
}

clearInstall(){
if [ -d $MainWorkDir/openMVG ] ; then
    echo
    echo "Removing previous files ..."
    rm -fr $MainWorkDir/openMVG
fi
}

installDeps
clearInstall
cloneGitHub
compileAndInstallOpenMVG
testOpenMVG

echo
echo "Ready to go. "



