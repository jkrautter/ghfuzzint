#!/bin/bash

CC=clang
CXX=clang++
CFLAGS='-O2 -fno-omit-frame-pointer -gline-tables-only -fsanitize=address,fuzzer-no-link -fsanitize-address-use-after-scope'
CXXFLAGS='-O2 -fno-omit-frame-pointer -gline-tables-only -fsanitize=address,fuzzer-no-link -fsanitize-address-use-after-scope'
JOBS=$(nproc)

cd fuzzer
rm -rf BUILD
set -ex
mkdir BUILD
cd BUILD
cmake -DCMAKE_C_COMPILER="$CC" \
      -DCMAKE_CXX_COMPILER="$CXX" \
      -DCMAKE_C_FLAGS="$CFLAGS -fcommon" \
      -DCMAKE_CXX_FLAGS="$CXXFLAGS -fcommon" \
      -DWITH_STATIC_LIB=ON ../..
make -j $JOBS
cd ..
$CXX $CXXFLAGS -std=c++11 fuzzer.cc -I ../include/ ./BUILD/src/libssh.a -fsanitize=fuzzer -lcrypto -lgss -lz -o fuzzer
rm -rf BUILD
rm -rf CORPUS
mkdir CORPUS
[ -e ./fuzzer ] && ./fuzzer -max_len=60 -artifact_prefix=CORPUS/ -jobs=$JOBS -workers=$JOBS -max_total_time=$1 ./CORPUS
grep "ERROR: LeakSanitizer: detected memory leaks" fuzz-*.log || echo "Fuzzer did not detect memory leaks!"
rm fuzz-*.log
rm -rf CORPUS
rm fuzzer
exit 0
