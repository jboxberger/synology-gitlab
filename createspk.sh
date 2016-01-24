#!/bin/bash
dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
path=""
copy=""
project="$2"
projectdir=""
if [ -z "$1" ]; then
    echo "please specify path"
	exit
fi

if [[ "$1" = /* ]]; then
   path=$1
else
   path=$dir/$1
fi

if [ ! -d "$path" ]; then
  echo "path $path not found!"
  exit
fi

copy=$path.tmp
projectdir="$(dirname $path)"   # Returns "/from/hear/to"
if [ -z "$project" ]; then
    project="$(basename $path)" # Returns just "to"
fi

cp -R $path $copy
cd $copy/package
tar -czf $copy/package.tgz *
rm -Rf $copy/package
cd $copy

if [ ! -d "$projectdir/bin" ]; then
  mkdir "$projectdir/bin"
fi
tar -cvf $projectdir/bin/$project.spk *
rm -Rf $copy

#docker pull quay.io/sameersbn/gitlab:8.2.3
#docker pull quay.io/sameersbn/redis:latest
#docker save --output="gitlab-8.2.3.tar" 'quay.io/sameersbn/gitlab:8.2.3'
#docker save --output="redis-latest.tar" 'quay.io/sameersbn/redis:latest'
#docker exec -it "synology_gitlab" bash



#/usr/syno/bin/synowebapi --exec api=SYNO.Docker.Container version=1 method=delete name=synology_gitlab_redis force=true preserve_profile=false
#/usr/syno/bin/synowebapi --exec api=SYNO.Docker.Container version=1 method=delete name=synology_gitlab force=true preserve_profile=false

#docker rmi quay.io/sameersbn/redis:latest
#docker rmi quay.io/sameersbn/gitlab:8.2.3

# Remove dangling images
#docker rmi $(docker images -q --filter dangling=true)

#compress extracted docker Images
# cd directory/
# XZ_OPT=-9 tar -Jcvf redis-latest.tar.xz *
# XZ_OPT=-9 tar -Jcvf gitlab-8.2.3.tar.xz *