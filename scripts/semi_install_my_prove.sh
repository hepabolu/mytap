#!/bin/bash
#
# Install my_prove

git clone https://github.com/theory/tap-parser-sourcehandler-mytap.git
mv tap-parser-sourcehandler-mytap myprove
cd myprove
env PERL_MM_USE_DEFAULT=1
perl Build.PL

# If necessary install dependencies
# ./Build installdeps
# ./Build manifest

./Build
./Build test
sudo ./Build install

# my_prove is located in myprove/bin

