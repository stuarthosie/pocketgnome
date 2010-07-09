# This script can be used to compile your own copy of libbz2.a, in case you're paranoid
# and think that my copy is going to give you a virus or something. I wouldn't tarnish
# my reputation in the community by pulling a stunt like that, but I respect your desire
# to keep your system safe. This script doesn't automatically get the newest version
# or anything like that, but since as of this writing (July 9th 2010) the latest version
# is over two years old (March 17 2008), so I don't think the project receives updates
# much. Enjoy! -wjlafrance@gmail.com

rm libbz2.a
wget http://www.bzip.org/1.0.5/bzip2-1.0.5.tar.gz
tar -xvvzf bzip2-1.0.5.tar.gz
rm bzip2-1.0.5.tar.gz
cd bzip2-1.0.5
make
cd ..
cp bzip2-1.0.5/libbz2.a .
rm -rf bzip2-1.0.5
echo libbz2.a compiled
