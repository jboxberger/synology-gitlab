#!/bin/bash
# save image from docker to tar.xz file for the AIO package

gitlab_target_version=10.2.5
redis_target_version=3.2.11

if [ $(dpkg-query -W -f='${Status}' docker.io 2>/dev/null | grep -c "ok installed") -eq 0 ] || \
   [ $(dpkg-query -W -f='${Status}' pxz 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    sudo apt-get update
    sudo apt-get install -y docker.io pxz
fi

sudo docker rmi $(sudo docker images -q)

sudo docker pull sameersbn/gitlab:$gitlab_target_version
sudo docker pull redis:$redis_target_version

echo "exporting sameersbn/gitlab:"$gitlab_target_version
sudo docker save sameersbn/gitlab | pxz > ~/gitlab-$gitlab_target_version.tar.xz

echo "exporting redis:"$redis_target_version
sudo docker save redis | pxz > ~/redis-$redis_target_version.tar.xz
