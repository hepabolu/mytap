#!/bin/bash
#
# Install my_prove

git clone https://github.com/theory/tap-parser-sourcehandler-mytap.git
mv tap-parser-sourcehandler-mytap myprove
cd myprove
perl Build.PL

# If necessary install dependencies
# ./Build installdeps
# ./Build manifest

./Build
./Build test
./Build install

# my_prove is located in myprove/bin
