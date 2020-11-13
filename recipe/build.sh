#!/bin/bash

set -e

DISABLES="--disable-cairo --disable-opencl --disable-cuda --disable-nvml"
DISABLES="$DISABLES --disable-gl --disable-libudev"

chmod +x configure

case `uname` in
    Darwin)
        ./configure --prefix=$PREFIX $DISABLES
        ;;
    Linux)
        export LDFLAGS="${LDFLAGS} -Wl,--as-needed"
        ./configure --prefix=$PREFIX $DISABLES
        ;;
    MINGW*)
        export PATH="$PREFIX/Library/bin:$BUILD_PREFIX/Library/bin:$RECIPE_DIR:$PATH"
        export CC="$RECIPE_DIR/cl_wrapper.sh"
        echo "$PATH"
        $CC --version
        export RANLIB=llvm-ranlib
        export AS=llvm-as
        export AR=llvm-ar
        export LD=link
        export CFLAGS="-MD -I$PREFIX/Library/include -O2"
        export CXXFLAGS="-MD -I$PREFIX/Library/include -O2"
        export LDFLAGS="$LDFLAGS -L$PREFIX/Library/lib -no-undefined $PREFIX/Library/lib/pthreads.lib"
        # Skip failing tests that are skipped on Linux x86_64 and OSX, but not skipped on windows
        sed -i "s|SUBDIRS += x86||g" tests/hwloc/Makefile.am
        sed -i "s|-Xlinker --output-def -Xlinker .libs/libhwloc.def||g" hwloc/Makefile.am
        autoreconf -i
        chmod +x configure
        chmod +x "$CC"
        ./configure --prefix="$PREFIX/Library" --libdir="$PREFIX/Library/lib" $DISABLES
        make V=1
        ;;
esac

make -j${CPU_COUNT}
if [[ "${CONDA_BUILD_CROSS_COMPILATION}" != "1" ]]; then
make check -j${CPU_COUNT}
fi
make install

PROJECT=hwloc
if [[ `uname` == MINGW* ]]; then
    LIBRARY_LIB=$PREFIX/Library/lib
    mv "${LIBRARY_LIB}/${PROJECT}.dll.lib" "${LIBRARY_LIB}/${PROJECT}.lib"
fi
