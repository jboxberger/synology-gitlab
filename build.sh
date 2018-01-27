#!/bin/bash

########################################################################################################################
# FUNCTIONS
########################################################################################################################
stringInArray() {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 1; done
  return 0
}


CopyOldConfig()
{
cat << EOF
if ! [ -f \$BACKUP_CONFIG ] \&\& [ -f "\/usr\/syno\/etc\/packages\/Docker-GitLab\/config" ]; then\n
  if ! [ -d "\$(dirname \$BACKUP_CONFIG)" ]; then\n
    mkdir -p "\$(dirname \$BACKUP_CONFIG)"\n
  fi\n
  cp "\/usr\/syno\/etc\/packages\/Docker-GitLab\/config" "\$BACKUP_CONFIG"\n
fi\n
EOF
}

NeedMigrateDBCustomFunction()
{
cat << EOF
NeedMigrateDBCustom()\n
{\n
  #version is the not upgraded (previous\/old) package version\n
  #so we need to check if the old version is already behind the MariaDB 10 migration\n
  local version=(\$(echo \$1 | tr -d '.' | tr "-" " "))\n
  local current_version="\${version[0]}"\n
	local current_subversion="\${version[1]}"\n
  \n
  local MIGRATE_CUSTOM_VERSION="1011"\n
  local MIGRATE_CUSTOM_SUBVERSION=""\n
  \n
  local MIGRATE_STOCK_VERSION="944"\n
  local MIGRATE_STOCK_SUBVERSION="0050"\n
  \n
  if [ -z "\$current_version" ]; then\n
    return 0\n
  fi\n
  \n
  #old version number always have subversion\n
  if ! [ -z "\$current_subversion" ] \&\& [ "\$current_version" -lt "\$MIGRATE_STOCK_VERSION" ]; then\n
		return 0\n
	fi\n
  \n
	if ! [ -z "\$current_subversion" ] \&\& [ "\$current_version" -le "\$MIGRATE_STOCK_VERSION" ] \&\& [ "\$current_subversion" -lt "\$MIGRATE_STOCK_SUBVERSION" ]; then\n
		return 0\n
	fi\n
  \n
	if [ -z "\$current_subversion" ] \&\& [ "\$current_version" -le "\$MIGRATE_CUSTOM_VERSION" ]; then\n
	  return 0\n
	fi\n
  \n
	return 1\n
}\n
EOF
}

########################################################################################################################
# DEFAULT PARAMETERS
########################################################################################################################
gitlab_target_package_fqn="sameersbn/gitlab:10.2.5"
gitlab_target_package_download_size=700

redis_target_package_fqn="redis:3.2.11"
redis_target_package_download_size=41

all_in_one="false"

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
        -rds=*|--redis-download-size=*)
            redis_target_package_download_size="${i#*=}"
        ;;
        -gv=*|--gitlab-fqn=*)
            gitlab_target_package_fqn="${i#*=}"
        ;;
        -gv=*|--gitlab-download-size=*)
            gitlab_target_package_download_size="${i#*=}"
        ;;
        --all-in-one)
            all_in_one="true"
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
gitlab_target_package_name=$(echo $gitlab_target_package_fqn | cut -f1 -d:)
gitlab_target_package_version=$(echo $gitlab_target_package_fqn | cut -f2 -d:)

redis_target_package_name=$(echo $redis_target_package_fqn | cut -f1 -d:)
redis_target_package_version=$(echo $redis_target_package_fqn | cut -f2 -d:)

########################################################################################################################
# VARIABLES
########################################################################################################################
base_package_url='https://usdl.synology.com/download/Package/spk/Docker-GitLab/9.4.4-0050/Docker-GitLab-broadwell-9.4.4-0050.spk'
base_package_filename="${base_package_url##*/}"
base_package_name="${base_package_filename%.*}"
base_package_version=$( echo $base_package_name | grep -P '([0-9]{1,2}[.][0-9]{1,2}[.]{0,1}[0-9]{0,2})' -o )

project_name=synology-gitlab
current_dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
download_dir=download
project_dir=source/$project_name
target_dir=build/$project_name/$gitlab_target_package_version

########################################################################################################################
# INIT
########################################################################################################################
if [ $(dpkg-query -W -f='${Status}' git 2>/dev/null | grep -c "ok installed") -eq 0 ] || \
  [ $(dpkg-query -W -f='${Status}' jq 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    sudo apt-get update
    sudo apt-get install -y git jq python
fi

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
tar -zxf $project_dir/package.tgz -C $project_dir/package
rm $project_dir/package.tgz
rm $project_dir/syno_signature.asc

synology_gitlab_config=$project_dir/package/config/synology_gitlab
redis_config=$project_dir/package/config/synology_gitlab_redis

#fix json to be able to work with jq
sed -i -e "s/:__HTTP_PORT__,/:\"__HTTP_PORT__\",/g" $project_dir/package/config/synology_gitlab
sed -i -e "s/:__SSH_PORT__,/:\"__SSH_PORT__\",/g" $project_dir/package/config/synology_gitlab

gitlab_base_package_fqn=$(jq '.image' <$synology_gitlab_config | tr -d '"')
gitlab_base_package_name=$(echo $gitlab_base_package_fqn | cut -f1 -d:)
gitlab_base_package_version=$(echo $gitlab_base_package_fqn | cut -f2 -d:)

redis_base_package_fqn=$(jq '.image' <$redis_config | tr -d '"')
redis_base_package_name=$(echo $redis_base_package_fqn | cut -f1 -d:)
redis_base_package_version=$(echo $redis_base_package_fqn | cut -f2 -d:)

########################################################################################################################
# MODIFY GITLAB VERSION
########################################################################################################################
jq -c --arg image "$gitlab_target_package_name:$gitlab_target_package_version"  '.image=$image' <$synology_gitlab_config >$synology_gitlab_config".out" && mv $synology_gitlab_config".out" $synology_gitlab_config
jq -c '.is_package=false' <$synology_gitlab_config >$synology_gitlab_config".out" && mv $synology_gitlab_config".out" $synology_gitlab_config

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
# RENAME PACKAGE
########################################################################################################################
rename_package=0

if [ $rename_package == 1 ]; then
  sed -i -e "/^package=/s/=.*/=\"$gitlab_mod_package_name\"/" $project_dir/INFO
  echo "install_replace_packages=\"$gitlab_stock_package_name\"" >> $project_dir/INFO
  #echo "install_conflict_packages=\"Docker-GitLab<9.4.4-0050\"" >> $project_dir/INFO
  echo 'firmware="6.1-15117"' >> $project_dir/INFO
  echo 'os_min_ver="6.1-15117"' >> $project_dir/INFO

  new_gitlab_redis_container_name="synology_gitlab_redis_two"
  sed -i -e "s|REDIS_NAME=synology_gitlab_redis|REDIS_NAME=\"$new_gitlab_redis_container_name\"|g" $project_dir/scripts/common
  sed -i -e "s|REDIS_PROFILE=\"\$TARGET_PATH\"/config/synology_gitlab_redis|REDIS_PROFILE=\"\$TARGET_PATH\"/config/$new_gitlab_redis_container_name |g" $project_dir/scripts/common
  sed -i -e "s| name=synology_gitlab_redis | name=$new_gitlab_redis_container_name |g" $project_dir/scripts/postuninst
  sed -i -e "s|\"synology_gitlab_redis\"|\"$new_gitlab_redis_container_name\"|g" $redis_config
  sed -i -e "s|\"synology_gitlab_redis\"|\"$new_gitlab_redis_container_name\"|g" $synology_gitlab_config

  new_gitlab_container_name="synology_gitlab_two"
  sed -i -e "s|GITLAB_NAME=synology_gitlab|GITLAB_NAME=\"$new_gitlab_container_name\"|g" $project_dir/scripts/common
  sed -i -e "s|GITLAB_PROFILE=\"\$TARGET_PATH\"/config/synology_gitlab|GITLAB_PROFILE=\"\$TARGET_PATH\"/config/$new_gitlab_container_name |g" $project_dir/scripts/common
  sed -i -e "s|/etc/synology_gitlab.config|/etc/$new_gitlab_container_name.config|g" $project_dir/scripts/common_custom
  sed -i -e "s| name=synology_gitlab | name=$new_gitlab_container_name |g" $project_dir/scripts/postuninst
  sed -i -e "s| name=synology_gitlab | name=$new_gitlab_container_name |g" $project_dir/scripts/postinst

  sed -i -e "s|\"synology_gitlab\"|\"$new_gitlab_container_name\"|g" $synology_gitlab_config

  mv $synology_gitlab_config "$(dirname $synology_gitlab_config)/$new_gitlab_container_name"
  mv $redis_config "$(dirname $redis_config)/$new_gitlab_redis_container_name"

  sed -i -e "s|$gitlab_stock_package_name|$gitlab_mod_package_name|g" $project_dir/scripts/common
  sed -i -e "s|$gitlab_stock_package_name|$gitlab_mod_package_name|g" $project_dir/package/ui/config
  sed -i -e "s|$gitlab_stock_package_name|$gitlab_mod_package_name|g" $project_dir/WIZARD_UIFILES/ui_common

  CopyOldConfig=$(echo $(CopyOldConfig) | sed 's/\./\\./g')
  sed -i "s/NeedRestore()/$CopyOldConfig\n\n&/" $project_dir/WIZARD_UIFILES/ui_common

  for wizzard_file in $project_dir/WIZARD_UIFILES/*.sh ; do
    sed -i -e "s|$gitlab_stock_package_name|$gitlab_mod_package_name|g" $wizzard_file
    sed -i "s/NeedRestore()/$CopyOldConfig\n\n&/" $wizzard_file
  done
fi
########################################################################################################################
# UPDATE INFO FILE
########################################################################################################################
sed -i -e "/^version=/s/=.*/=\"$gitlab_target_package_version\"/" $project_dir/INFO
sed -i -e "/^distributor=/s/=.*/=\"Synology Inc. mod by $gitlab_mod_maintainer\"/" $project_dir/INFO
sed -i -e "/^arch=/s/=.*/=\"x86 avoton bromolow cedarview braswell kvmx64 broadwell apollolake\"/" $project_dir/INFO
echo "distributor_url=\"$gitlab_mod_maintainer_url\"" >> $project_dir/INFO
echo "install_conflict_packages=\"Docker-GitLab<9.4.4\"" >> $project_dir/INFO

########################################################################################################################
# UPDATE SCRIPT FILES
########################################################################################################################
sed -i -e "s|$gitlab_base_package_fqn|$gitlab_target_package_fqn|g" $project_dir/scripts/postuninst
sed -i -e "s|$redis_base_package_fqn|$redis_target_package_fqn|g" $project_dir/scripts/postuninst

sed -i -e "s|^\s*\(SIZE_GITLAB\s*=\s*\).*\$|\1$gitlab_target_package_download_size|g" $project_dir/scripts/postinst
sed -i -e "s|^\s*\(SIZE_REDIS\s*=\s*\).*\$|\1$redis_target_package_download_size|g" $project_dir/scripts/postinst

sed -i -e "s|$gitlab_base_package_name $gitlab_base_package_version|$gitlab_target_package_name $gitlab_target_package_version|g" $project_dir/scripts/postinst
sed -i -e "s|gitlab-$gitlab_base_package_version.tar.xz|gitlab-$gitlab_target_package_version.tar.xz|g" $project_dir/scripts/postinst

sed -i -e "s|$redis_base_package_name $redis_base_package_version|$redis_target_package_name $redis_target_package_version|g" $project_dir/scripts/postinst
sed -i -e "s|redis-$redis_base_package_version.tar.xz|redis-$redis_target_package_version.tar.xz|g" $project_dir/scripts/postinst

########################################################################################################################
# INJECT HOOKS, CODE AND DATA
########################################################################################################################
echo '. "$(dirname $0)"/common_custom' >> $project_dir/scripts/common
sed -i '/. "$(dirname "$0")"\/common/a . "$(dirname "$0")"\/preupgrade_custom' $project_dir/scripts/preupgrade
#sed -i 's/exit 0/. "$(dirname "$0")"\/postupgrade_custom\n&/' $project_dir/scripts/postupgrade
sed -i 's/\/var\/packages\/Docker\/target\/tool\/helper \\/RestoreCustomEnvironmentVariables\nRestoreContainerPorts\n\n&/' $project_dir/scripts/postinst
sed -i '/rm "$ETC_PATH"\/config/a\\trm "$ETC_PATH"\/config_custom\n\trm "$ETC_PATH"\/config_container_ports' $project_dir/scripts/postuninst

########################################################################################################################
# MIGRATE MariaDB 5 to MariaDB 10 FIX
########################################################################################################################
NeedMigrateDBCustomFunction=$(echo $(NeedMigrateDBCustomFunction) | sed 's/\./\\./g')
sed -i "s/NeedMigrateDB()/$NeedMigrateDBCustomFunction\n\n&/" $project_dir/WIZARD_UIFILES/ui_common
sed -i -e "s|if NeedMigrateDB \"\$OLD_BUILD_NUMBER\"; then|if NeedMigrateDBCustom \"\$SYNOPKG_OLD_PKGVER\"; then|g" $project_dir/scripts/preupgrade

for wizzard_file in $project_dir/WIZARD_UIFILES/*.sh ; do
  sed -i "s/NeedMigrateDB()/$NeedMigrateDBCustomFunction\n\n&/" $wizzard_file
  sed -i -e "s|if NeedMigrateDB \"\$version\"; then|if NeedMigrateDBCustom \"\$SYNOPKG_OLD_PKGVER\"; then|g" $wizzard_file
done

########################################################################################################################
# Disable Redis Logging
########################################################################################################################
sed -i  '/$API --exec api=SYNO.Docker.Container version=1 method=delete name=synology_gitlab force=true preserve_profile=false/a $API --exec api=SYNO.Docker.Container version=1 method=delete name=synology_gitlab_redis force=true preserve_profile=false \n\n$API --exec api=SYNO.Docker.Container version=1 method=create is_run_instantly=true \\\n  profile="$(cat "$REDIS_PROFILE")" || exit 1' $project_dir/scripts/postinst
if [ "$redis_target_package_name" == "redis" ]; then # do not modify 'sameersbn/redis'
    # save "43200 1" # <seconds> <at least changes> ->each 12h
    # save "86400 1" # <seconds> <at least changes> ->each 24h
    sed -i 's/exit 0/\n$DOCKER_BIN exec "$REDIS_NAME" sed -i -e '"'"'s|^exec "$@"$|exec "\$@" --save ""|g'"'"' \/usr\/local\/bin\/docker-entrypoint.sh\n&/' $project_dir/scripts/postinst
fi

if [ "$all_in_one" == "true" ]; then
    mkdir -p "$project_dir/package/docker"
    if [ -f "docker/gitlab-$gitlab_target_package_version.tar.xz" ]; then
        cp -rf "docker/gitlab-$gitlab_target_package_version.tar.xz" "$project_dir/package/docker/gitlab-$gitlab_target_package_version.tar.xz"
    fi
    if [ -f "docker/redis-$redis_target_package_version.tar.xz" ]; then
        cp -rf "docker/redis-$redis_target_package_version.tar.xz" "$project_dir/package/docker/redis-$redis_target_package_version.tar.xz"
    fi
fi

########################################################################################################################
# PACKAGE BUILD
########################################################################################################################
aios="" #all-in-one-package
if [ "$all_in_one" == "true" ]; then
    aios="aio-"
fi

# compress package dir
cd $project_dir/package/ && tar -zcf ../package.tgz * && cd ../../../
rm -rf $project_dir/package/

EXTRACTSIZE=$(du -k --block-size=1KB "$project_dir/package.tgz" | cut -f1)
sed -i -e "/^extractsize=/s/=.*/=\"$EXTRACTSIZE\"/" $project_dir/INFO

# create spk-name
new_file_name=$project_name"-stock-"$aios$gitlab_target_package_version".spk"

cd $project_dir/ && tar --format=gnu -cf ../../$target_dir/$new_file_name * && cd ../../

if [ "$all_in_one" != "true" ]; then
    ./build.sh --gitlab-fqn=$gitlab_target_package_fqn --gitlab-download-size=$gitlab_target_package_download_size --redis-fqn=$redis_target_package_fqn --redis-download-size=$redis_target_package_download_size --all-in-one
fi
