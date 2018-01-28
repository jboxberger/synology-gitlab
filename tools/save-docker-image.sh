#!/bin/bash
# save image from docker to tar.xz file for the AIO package

########################################################################################################################
# install dependencies
########################################################################################################################
if [ $(dpkg-query -W -f='${Status}' docker.io 2>/dev/null | grep -c "ok installed") -eq 0 ] || \
   [ $(dpkg-query -W -f='${Status}' pxz 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    sudo apt-get update
    sudo apt-get install -y docker.io pxz
fi

########################################################################################################################
# The command line help
########################################################################################################################
display_help() {
    echo "Usage: $0 [option...]" >&2
    echo
    echo "   --image       docker image you want to save <image_name>:<version>"
    echo "   --target-dir  image file destination directory"
    echo "   --delete      deletes pulled image after export"
    echo
    # echo some stuff here for the -a or --add-options
    exit 1
}

########################################################################################################################
# PARAMETER HANDLING
########################################################################################################################
IMAGE=""
KEEP_IMAGE=0
TARGET_DIR="/home/$USER/docker-images"
for i in "$@"
do
    case $i in
        -i=*|--image=*)
            IMAGE="${i#*=}"
        ;;
        -t=*|--target-dir=*)
            TARGET_DIR="${i#*=}"
        ;;
        -k|--keep-image)
            KEEP_IMAGE=1
        ;;
        -h|--help)
            display_help  # Call your function
            exit 0
        ;;
        *)
            # unknown option
        ;;
    esac
    shift
done

########################################################################################################################
# VALIDATE PARAMETER DEPENDENCIES
########################################################################################################################
if [ -z "$IMAGE" ]; then
    echo "--image is not set!"
    display_help
    exit 1
fi

if ! [ -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
    if ! [ -d "$TARGET_DIR" ]; then
      exit 1
    fi
fi

image_array=($(echo "$IMAGE" | tr ":" " "))
image_name="${image_array[0]}"
image_version="${image_array[1]}"

if [ -z "$image_name" ]; then
    echo "--image $image do not contain image name"
    display_help
    exit 1
fi

if [ -z "$image_version" ]; then
    echo "--image $image do not contain image version"
    display_help
    exit 1
fi

#sudo docker rmi $(sudo docker images -q)

echo "pull image $image_name:$image_version"
sudo docker pull "$image_name:$image_version"

echo "export image $image_name:$image_version"
sudo docker save "$image_name" | pxz > "$TARGET_DIR/$(echo "$image_name" | tr '/' '-')-$image_version.tar.xz"

if [ "$KEEP_IMAGE" == 0 ]; then
  echo "deleting image $image_name:$image_version"
  sudo docker rmi "$image_name:$image_version"
fi
