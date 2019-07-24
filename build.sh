#!/bin/bash

IS_DEBUG=0
spk_version=0054

########################################################################################################################
# FUNCTIONS
########################################################################################################################
stringInArray() {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 1; done
  return 0
}

########################################################################################################################
# CHECK DEPENDENCIES!
########################################################################################################################
if [ $(dpkg-query -W -f='${Status}' git 2>/dev/null | grep -c "ok installed") -eq 0 ] || \
  [ $(dpkg-query -W -f='${Status}' jq 2>/dev/null | grep -c "ok installed") -eq 0 ] || \
  [ $(dpkg-query -W -f='${Status}' python 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    sudo apt-get update
    sudo apt-get install -y git jq python
fi


########################################################################################################################
# DEFAULT PARAMETERS
########################################################################################################################
gitlab_target_package_fqn="sameersbn/gitlab:11.0.4"
gitlab_target_package_download_size=896

postgresql_target_package_fqn="sameersbn/postgresql:10"
postgresql_target_package_download_size=95

redis_target_package_fqn="redis:3.2.6"
redis_target_package_download_size=29

gitlab_stock_package_name="Docker-GitLab"
gitlab_stock_package_url="https://www.synology.com/de-de/dsm/packages/Docker-GitLab"

gitlab_mod_package_name="docker-gitlab"
gitlab_mod_maintainer="Juri Boxberger"
gitlab_mod_maintainer_url="https://github.com/jboxberger/synology-gitlab"

########################################################################################################################
# PARAMETER HANDLING
########################################################################################################################
for i in "$@"
do
    case $i in
        -rv=*|--redis-fqn=*)
            redis_target_package_fqn="${i#*=}"
        ;;
        -rs=*|--redis-download-size=*)
            redis_target_package_download_size="${i#*=}"
        ;;
        -pv=*|--postgresql-fqn=*)
            postgresql_target_package_fqn="${i#*=}"
        ;;
        -ps=*|--postgresql-download-size=*)
            postgresql_target_package_download_size="${i#*=}"
        ;;
        -gv=*|--gitlab-fqn=*)
            gitlab_target_package_fqn="${i#*=}"
        ;;
        -gs=*|--gitlab-download-size=*)
            gitlab_target_package_download_size="${i#*=}"
        ;;
        -v=*|--spk-version=*)
            spk_version="${i#*=}"
        ;;
        --debug)
            IS_DEBUG=1
        ;;
        *)
            # unknown option
        ;;
    esac
    shift
done

########################################################################################################################
# PROCESS VARIABLES
########################################################################################################################
gitlab_target_package_name=$(echo "$gitlab_target_package_fqn" | cut -f1 -d:)
gitlab_target_package_version=$(echo "$gitlab_target_package_fqn" | cut -f2 -d:)
gitlab_target_package_name_escaped=$(echo "$gitlab_target_package_name" | tr '/' '-')

postgresql_target_package_name=$(echo "$postgresql_target_package_fqn" | cut -f1 -d:)
postgresql_target_package_version=$(echo "$postgresql_target_package_fqn" | cut -f2 -d:)
postgresql_target_package_name_escaped=$(echo "$postgresql_target_package_name" | tr '/' '-')

redis_target_package_name=$(echo "$redis_target_package_fqn" | cut -f1 -d:)
redis_target_package_version=$(echo "$redis_target_package_fqn" | cut -f2 -d:)
redis_target_package_name_escaped=$(echo "$redis_target_package_name" | tr '/' '-')

########################################################################################################################
# VARIABLES
########################################################################################################################
base_package_url='https://usdl.synology.com/download/Package/spk/Docker-GitLab/11.0.4-0054/Docker-GitLab-x64-11.0.4-0054.spk'
base_package_filename="${base_package_url##*/}"
base_package_name="${base_package_filename%.*}"
base_package_version=$( echo $base_package_name | grep -P '([0-9]{1,2}[.][0-9]{1,2}[.]{0,1}[0-9]{0,2})' -o )

project_name=synology-gitlab
current_dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
download_dir=download
project_dir=source/$project_name
target_dir=build/$project_name/$gitlab_target_package_version

DOCKER_IMAGE_DIR="$current_dir/docker"

########################################################################################################################
# INIT
########################################################################################################################
if [ -d $project_dir ]; then
    rm -rf $project_dir
fi

mkdir -p $project_dir
mkdir -p $project_dir/package

if ! [ -d $download_dir ]; then
    mkdir -p $download_dir
fi

if ! [ -d $target_dir ]; then
    mkdir -p $target_dir
fi

########################################################################################################################
# INITIALIZE BASE PACKAGE
########################################################################################################################
if ! [ -f $download_dir/$base_package_filename ]; then
    cd $download_dir
    curl -L -J -O $base_package_url
    cd $current_dir
fi

tar xf "$download_dir/$base_package_filename" -C $project_dir
tar xf $project_dir/package.tgz -C $project_dir/package

rm $project_dir/package.tgz
rm $project_dir/syno_signature.asc

synology_gitlab_config=$project_dir/package/config/synology_gitlab
synology_gitlab_postgresql_config=$project_dir/package/config/synology_gitlab_postgresql
redis_config=$project_dir/package/config/synology_gitlab_redis

#fix json to be able to work with jq
sed -i -e "s/:__HTTP_PORT__,/:\"__HTTP_PORT__\",/g" $project_dir/package/config/synology_gitlab
sed -i -e "s/:__SSH_PORT__,/:\"__SSH_PORT__\",/g" $project_dir/package/config/synology_gitlab

gitlab_base_package_fqn=$(jq '.image' <$synology_gitlab_config | tr -d '"')
gitlab_base_package_name=$(echo $gitlab_base_package_fqn | cut -f1 -d:)
gitlab_base_package_version=$(echo $gitlab_base_package_fqn | cut -f2 -d:)

postgresql_base_package_fqn=$(jq '.image' <$synology_gitlab_postgresql_config | tr -d '"')
postgresql_base_package_name=$(echo $postgresql_base_package_fqn | cut -f1 -d:)
postgresql_base_package_version=$(echo $postgresql_base_package_fqn | cut -f2 -d:)

redis_base_package_fqn=$(jq '.image' <$redis_config | tr -d '"')
redis_base_package_name=$(echo $redis_base_package_fqn | cut -f1 -d:)
redis_base_package_version=$(echo $redis_base_package_fqn | cut -f2 -d:)

########################################################################################################################
# MODIFY PACKAGE VERSIONS
########################################################################################################################
jq -c --arg image "$gitlab_target_package_name:$gitlab_target_package_version"  '.image=$image' <$synology_gitlab_config >$synology_gitlab_config".out" && mv $synology_gitlab_config".out" $synology_gitlab_config
jq -c '.is_package=false' <$synology_gitlab_config >$synology_gitlab_config".out" && mv $synology_gitlab_config".out" $synology_gitlab_config

jq -c --arg image "$postgresql_target_package_name:$postgresql_target_package_version"  '.image=$image' <$synology_gitlab_postgresql_config >$synology_gitlab_postgresql_config".out" && mv $synology_gitlab_postgresql_config".out" $synology_gitlab_postgresql_config
jq -c '.is_package=false' <$synology_gitlab_postgresql_config >$synology_gitlab_postgresql_config".out" && mv $synology_gitlab_postgresql_config".out" $synology_gitlab_postgresql_config

jq -c --arg image "$redis_target_package_name:$redis_target_package_version"  '.image=$image' <$redis_config >$redis_config".out" && mv $redis_config".out" $redis_config
jq -c '.is_package=false' <$redis_config >$redis_config".out" && mv $redis_config".out" $redis_config

########################################################################################################################
# SET DEFAULT ENV VARS
########################################################################################################################
env_default="$PWD"/env_default
if [ -s $env_default ]
then
    i=0
    tmp_keys=$(jq '.env_variables[].key' <"$synology_gitlab_config" | tr -d '"')
    while read line
    do
        keys[$i]="$line"
        (( i++ ))
    done <<< "${tmp_keys[@]}"

    while read LINE;
    do
        key=$(echo $LINE | cut -f1 -d=)
        value=$(echo $LINE | cut -f2 -d=)
        value=$(echo "$value" | tr -d '\r') # trim \r on line-end
        stringInArray "$key" "${keys[@]}"
        if [ $? == 1 ]; then
            index=$(echo ${keys[@]/$key//} | cut -d/ -f1 | wc -w | tr -d ' ')
            jq -c ".env_variables[$index].value=\"$value\""  <$synology_gitlab_config >$synology_gitlab_config".out" && mv $synology_gitlab_config".out" $synology_gitlab_config
        else
            jq -c ".env_variables += [{\"key\" : \"$key\", \"value\" : \"$value\"}]"  <$synology_gitlab_config >$synology_gitlab_config".out" && mv $synology_gitlab_config".out" $synology_gitlab_config
        fi
    done < $env_default
fi

########################################################################################################################
# Add Custom Content
########################################################################################################################
if [ -d overwrite/$project_name ]; then
    cp -Rf overwrite/$project_name/* source/$project_name/
fi

########################################################################################################################
# UPDATE INFO FILE
########################################################################################################################
sed -i -e "/^version=/s/=.*/=\"$gitlab_target_package_version-$spk_version\"/" $project_dir/INFO
sed -i -e "/^distributor=/s/=.*/=\"Synology Inc. mod by $gitlab_mod_maintainer\"/" $project_dir/INFO
echo "distributor_url=\"$gitlab_mod_maintainer_url\"" >> $project_dir/INFO

########################################################################################################################
# UPDATE SCRIPT FILES
########################################################################################################################
sed -i -e "s|$gitlab_base_package_fqn|$gitlab_target_package_fqn|g" $project_dir/scripts/postuninst
sed -i -e "s|$postgresql_base_package_fqn|$postgresql_target_package_fqn|g" $project_dir/scripts/postuninst
sed -i -e "s|$redis_base_package_fqn|$redis_target_package_fqn|g" $project_dir/scripts/postuninst

sed -i -e "s|^\s*\(SIZE_GITLAB\s*=\s*\).*\$|\1$gitlab_target_package_download_size|g" $project_dir/scripts/postinst
sed -i -e "s|^\s*\(SIZE_POSTGRESQL\s*=\s*\).*\$|\1$postgresql_target_package_download_size|g" $project_dir/scripts/postinst
sed -i -e "s|^\s*\(SIZE_REDIS\s*=\s*\).*\$|\1$redis_target_package_download_size|g" $project_dir/scripts/postinst

sed -i -e "s|$gitlab_base_package_name $gitlab_base_package_version|$gitlab_target_package_name $gitlab_target_package_version|g" $project_dir/scripts/postinst
sed -i -e "s|$postgresql_base_package_name $postgresql_base_package_version|$postgresql_target_package_name $postgresql_target_package_version|g" $project_dir/scripts/postinst
sed -i -e "s|$redis_base_package_name $redis_base_package_version|$redis_target_package_name $redis_target_package_version|g" $project_dir/scripts/postinst

########################################################################################################################
# Disable Redis Logging
########################################################################################################################
#sed -i  '/$API --exec api=SYNO.Docker.Container version=1 method=delete name=synology_gitlab force=true preserve_profile=false/a $API --exec api=SYNO.Docker.Container version=1 method=delete name=synology_gitlab_redis force=true preserve_profile=false \n\n$API --exec api=SYNO.Docker.Container version=1 method=create is_run_instantly=true \\\n  profile="$(cat "$REDIS_PROFILE")" || exit 1' $project_dir/scripts/postinst
#if [ "$redis_target_package_name" == "redis" ]; then # do not modify 'sameersbn/redis'
#    # save "43200 1" # <seconds> <at least changes> ->each 12h
#    # save "86400 1" # <seconds> <at least changes> ->each 24h
#    sed -i 's/exit 0/\n$DOCKER_BIN exec "$REDIS_NAME" sed -i -e '"'"'s|^exec "$@"$|exec "\$@" --save ""|g'"'"' \/usr\/local\/bin\/docker-entrypoint.sh\n&/' $project_dir/scripts/postinst
#fi

########################################################################################################################
# INJECT HOOKS, CODE AND DATA
########################################################################################################################
echo '. "$(dirname $0)"/common_custom' >> $project_dir/scripts/common
sed -i '/. "$(dirname "$0")"\/common/a . "$(dirname "$0")"\/preupgrade_custom' $project_dir/scripts/preupgrade
sed -i 's/\/var\/packages\/Docker\/target\/tool\/helper \\/RestoreCustomEnvironmentVariables\nRestoreContainerPorts\n\n&/' $project_dir/scripts/postinst
sed -i '/rm "$ETC_PATH"\/config/a\\trm "$ETC_PATH"\/config_custom\n\trm "$ETC_PATH"\/config_container_ports' $project_dir/scripts/postuninst

########################################################################################################################
# COPY docker images
########################################################################################################################
mkdir -p "$project_dir/package/docker"
if [ -f "docker/$gitlab_target_package_name_escaped-$gitlab_target_package_version.tar.xz" ]; then
    cp -rf "docker/$gitlab_target_package_name_escaped-$gitlab_target_package_version.tar.xz" "$project_dir/package/docker/gitlab.tar.xz"
fi
if [ -f "docker/$postgresql_target_package_name_escaped-$postgresql_target_package_version.tar.xz" ]; then
    cp -rf "docker/$postgresql_target_package_name_escaped-$postgresql_target_package_version.tar.xz" "$project_dir/package/docker/postgresql.tar.xz"
fi
if [ -f "docker/$redis_target_package_name_escaped-$redis_target_package_version.tar.xz" ]; then
    cp -rf "docker/$redis_target_package_name_escaped-$redis_target_package_version.tar.xz" "$project_dir/package/docker/redis.tar.xz"
fi

########################################################################################################################
# PACKAGE BUILD
########################################################################################################################

# compress package dir
cd $project_dir/package/ && tar -zcf ../package.tgz * && cd ../../../
rm -rf $project_dir/package/

EXTRACTSIZE=$(du -k --block-size=1KB "$project_dir/package.tgz" | cut -f1)
sed -i -e "/^extractsize=/s/=.*/=\"$EXTRACTSIZE\"/" $project_dir/INFO

# create spk-name
new_file_name=$project_name"-stock-aio-"$gitlab_target_package_version"-"$spk_version".spk"

cd $project_dir/ && tar --format=gnu -cf ../../$target_dir/$new_file_name * && cd ../../
