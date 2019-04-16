CURDIR=`pwd`
shopt -s extglob
#docker run -it --rm --mount src=$CURDIR,target=/sonnenPoC,type=bind sonnendocker /bin/sh 

docker run -it --rm --mount src=$CURDIR,target=/sonnenPoC,type=bind sonnendocker 
