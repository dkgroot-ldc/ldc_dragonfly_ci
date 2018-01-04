#!/usr/bin/env bash
#
# set -e
export DMD_BASEDIR=`pwd`
export NCPU=${NCPU:-2}
export OS=${OS:-dragonflybsd}
export MODEL=${MODEL:-64}
export MAKE=gmake
export GITUSER=dkgroot
export QUIET=""

bootstrap() {
    cd ${DMD_BASEDIR}
    CURSTAGE=bootstrap

    echo "Running ${CURSTAGE} Compilation (NCPU:$NCPU / OS:$OS / MODEL:$MODEL)..."
    [ ! -d ${CURSTAGE} ] && mkdir ${CURSTAGE}
    pushd ${CURSTAGE}
            #if [ ! -d dmd ]; then
            #         git clone -b v2.067.1 https://github.com/dlang/dmd.git
            #         cd dmd
            #         git apply --reject ${DMD_BASEDIR}/patches/v2.067.1.patch
            #         mkdir -p ini/dragonflybsd/bin64
            #         cp ini/freebsd/bin64/dmd.conf ini/dragonflybsd/bin64/
            #         cd ..
            #fi
            [ ! -d dmd ] && git clone -b dragonflybsd_v2.067.1 https://github.com/${GITUSER}/dmd.git
            [ ! -d druntime ] && git clone -b dmd-cxx https://github.com/${GITUSER}/druntime.git
            [ ! -d phobos ] && git clone -b dmd-cxx https://github.com/${GITUSER}/phobos.git
            pushd dmd
                    echo "-----------------------------------------------------------------------------------------------------"
                    echo "running: $MAKE -f posix.mak MODEL=${MODEL} QUIET="${QUIET}" HOST_CSS=g++ -j${NCPU} $*"
                    echo "-----------------------------------------------------------------------------------------------------"
                    $MAKE -f posix.mak MODEL=${MODEL} QUIET="${QUIET}" HOST_CSS=g++ -j${NCPU} $*
                    [ $? -eq 0 ] || exit 1
            popd
            for dir in druntime phobos; do
                    pushd ${dir}
                            echo "-----------------------------------------------------------------------------------------------------"
                            echo "running: $MAKE -f posix.mak MODEL=${MODEL} QUIET="${QUIET}" HOST_CSS=g++ $*"
                            echo "-----------------------------------------------------------------------------------------------------"
                            $MAKE -f posix.mak MODEL=${MODEL} QUIET="${QUIET}" HOST_CSS=g++ $*
                            [ $? -eq 0 ] || exit 2
                    popd
            done
    popd
}

master() {
    cd ${DMD_BASEDIR}
    CURSTAGE=master

    echo "Running ${CURSTAGE} Compilation (NCPU:$NCPU / OS:$OS / MODEL:$MODEL)..."
    [ ! -d ${CURSTAGE} ] && mkdir ${CURSTAGE}
    pushd ${CURSTAGE}
            #[ ! -d dmd ] && git clone -b dragonflybsd-master https://github.com/${GITUSER}/dmd.git
            [ ! -d dmd ] && git clone https://github.com/dlang/dmd.git
            #[ ! -d druntime ] && git clone -b dragonflybsd-master https://github.com/${GITUSER}/druntime.git
            [ ! -d druntime ] && {
            	git clone https://github.com/${GITUSER}/druntime.git
            	cd druntime
            	git checkout -b unittest
            	git pull origin dragonflybsd-master dragonfly-core.sys.posix dragonfly-core.sys.dragonflybsd --commit -q --squash
            	cd ..
            }
            [ ! -d phobos ] && git clone -b dragonflybsd-master https://github.com/${GITUSER}/phobos.git
            export BOOTSTRAP_DMD=${DMD_BASEDIR}/bootstrap/install/${OS}/bin${MODEL}/dmd
            pushd dmd
                    echo "-----------------------------------------------------------------------------------------------------"
                    echo "running: $MAKE -f posix.mak MODEL=${MODEL} QUIET="${QUIET}" HOST_CSS=g++ -j${NCPU} HOST_DMD=${BOOTSTRAP_DMD} $*"
                    echo "-----------------------------------------------------------------------------------------------------"
                    $MAKE -f posix.mak MODEL=${MODEL} QUIET="${QUIET}" HOST_CSS=g++ -j${NCPU} HOST_DMD=${BOOTSTRAP_DMD} $*
                    [ $? -eq 0 ] || exit 1
            popd
            for dir in druntime phobos; do
                    pushd ${dir}
                            echo "-----------------------------------------------------------------------------------------------------"
                            echo "running: $MAKE -f posix.mak MODEL=${MODEL} QUIET="${QUIET}" HOST_CSS=g++ HOST_DMD=${BOOTSTRAP_DMD} $*"
                            echo "-----------------------------------------------------------------------------------------------------"
                            $MAKE -f posix.mak MODEL=${MODEL} QUIET="${QUIET}" HOST_CSS=g++ HOST_DMD=${BOOTSTRAP_DMD} $*
	                    [ $? -eq 0 ] || exit 2
                    popd
            done
    popd
}

tools() {
	CURSTAGE=master
	pushd ${CURSTAGE}
        if [ ! -d tools ]; then
        	git clone https://github.com/${GITUSER}/tools.git
        	cd tools
        	#git apply --reject ../../patches/tools.patch
        	curl -s https://raw.githubusercontent.com/dkgroot/dragonflybsd_dmd_port/master/patches/tools.patch -o tools.patch
        	git apply --reject tools.patch
	        [ $? -eq 0 ] || exit 1
        	cd ..
        fi
        pushd tools
        echo "-----------------------------------------------------------------------------------------------------"
        echo "building tools..."
        echo "-----------------------------------------------------------------------------------------------------"
        $MAKE -f posix.mak MODEL=${MODEL} QUIET="${QUIET}" OS=${OS}
        [ $? -eq 0 ] || exit 2
        popd
        popd
}

dub_unittest() {
	CURSTAGE=master
	pushd ${CURSTAGE}
        if [ ! -d dub ]; then
		git clone https://github.com/${GITUSER}/dub.git
		cd dub
        	#git apply --reject ../../patches/dub.patch
        	curl -s https://raw.githubusercontent.com/dkgroot/dragonflybsd_dmd_port/master/patches/dub.patch -o dub.patch
        	git apply --reject tools.patch
	        [ $? -eq 0 ] || exit 1
        	cd ..
        fi
        pushd dub
        echo "-----------------------------------------------------------------------------------------------------"
        echo "building dub..."
        echo "-----------------------------------------------------------------------------------------------------"
        DMD=${DMD_BASEDIR}/master/install/dragonflybsd/bin64/dmd ./build.sh || exit 1 
        echo "-----------------------------------------------------------------------------------------------------"
        echo "running unittests..."
        echo "-----------------------------------------------------------------------------------------------------"
        DUB=${DMD_BASEDIR}/master/dub/bin/dub DC=${DMD_BASEDIR}/master/install/dragonflybsd/bin64/dmd test/run-unittest.sh
        [ $? -eq 0 ] || exit 2
        popd
        popd
}

echo "Excuting '$@'"
$@
