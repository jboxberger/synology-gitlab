#!/bin/bash
docker_no_autopull=0
docker_no_autoclean=0
spk_version=0068

if [ "${USER}" == "root" ]; then
  echo "NO! You can not run this script as ROOT!"
  exit
fi

########################################################################################################################
# CHECK DEPENDENCIES!
########################################################################################################################
# ubuntu
APT_PACKAGES="xz-utils git jq curl docker.io"
APT_BINARY=""
if [ -f "/usr/bin/apt" ]; then
  APT_BINARY="/usr/bin/apt"
fi

# manjaro
PACMAN_BINARY=""
PACMAN_PACKAGES="xz git jq curl docker"
if [ -f "/usr/bin/pacman" ]; then
  PACMAN_BINARY="/usr/bin/pacman"
fi

if [ -n "${APT_BINARY}" ]; then
  echo "${APT_PACKAGES}" | tr ' ' '\n' | while read item; do
    if [ $(dpkg-query -W -f='${Status}' "${item}" 2>/dev/null | grep -c "ok installed") -eq 0 ]; then #apt -qq list docker.io
      echo "${item} is not installed."
      echo "executing: sudo apt install -y ${item}"
      sudo apt install -y "${item}"
      if [ "${item}" == "docker.io" ]; then
        sudo usermod -aG docker "${USER}"
        sudo systemctl enable docker
        sudo systemctl start docker
        echo "==================================================="
        echo "    please continue after re-login or restart.     "
        echo "==================================================="
        kill $$
      fi
    fi
  done
fi

if [ -n "${PACMAN_BINARY}" ]; then
  echo "${PACMAN_PACKAGES}" | tr ' ' '\n' | while read item; do
    if [ -z "$(pacman -Qs "${item}")" ]; then
      echo "${item} is not installed."
      echo "executing: sudo pacman -S ${item}"
      sudo pacman -S --noconfirm "${item}"
      if [ "${item}" == "docker" ]; then
        sudo usermod -aG docker "${USER}"
        sudo systemctl enable docker
        sudo systemctl start docker
        echo "==================================================="
        echo "    please continue after re-login or reboot.      "
        echo "==================================================="
        kill $$
      fi
    fi
  done
fi

########################################################################################################################
# FUNCTIONS
########################################################################################################################
in_array() {
  local e match="${1}"
  shift
  for e; do [[ "${e}" == "${match}" ]] && return 1; done
  return 0
}

strstr() {
  my_string="${1}"
  substring="${2}"

  if [ "${my_string/$substring}" != "$my_string" ] ; then
    echo "1"
  fi
  echo "0"
}

download_docker_image_interactive() {
  local image_name="${1}"
  local image_version="${2}"
  local target_dir="${3}"

  # shellcheck disable=SC2155
  local image_name_escaped="$(echo "${image_name}" | tr '/' '-')"

  if [ ! -f "${target_dir}/${image_name_escaped}-${image_version}.tar.xz" ]; then
    read -ep "docker image ${image_name}:${image_version} export not found. export? [Y/n]: " export
    if [ -z "${export}" ] || [ "${export}" != "n" ] ; then
      download_docker_image "${image_name}" "${image_version}" "${docker_dir}"
    fi
  fi
}

download_docker_image() {
  local image_name="${1}"
  local image_version="${2}"
  local target_dir="${3}"

  # shellcheck disable=SC2155
  local image_name_escaped=$(echo "${image_name}" | tr '/' '-')
  local pulled_image=0
  local success=0
  if [ ! -f "${target_dir}/${image_name_escaped}-${image_version}.tar.xz" ]; then

    if [ -z "$(docker images -q ${image_name}:${image_version} 2> /dev/null)" ]; then
      echo "pull image ${image_name}:${image_version}"
      docker pull "${image_name}:${image_version}" && success=1
      if [ ${success} -ne 1 ]; then
        echo "failed to pull image ${image_name}:${image_version}, build aborted!"
        exit 1
      fi
      pulled_image=1
    fi

    echo "export image ${image_name}:${image_version}"
    docker save "${image_name}:${image_version}" | xz --threads=0 --compress --verbose > "${target_dir}/${image_name_escaped}-${image_version}.tar.xz.tmp"
    mv "${target_dir}/${image_name_escaped}-${image_version}.tar.xz.tmp" "${target_dir}/${image_name_escaped}-${image_version}.tar.xz"

    if [ ${pulled_image} -eq 1 ] && [ ${docker_no_autoclean} -eq 0 ]; then
      echo "deleting image ${image_name}:${image_version}"
      docker rmi "${image_name}:${image_version}"
    fi
  fi
}

get_latest_version_number_from_dockerhub() {
  local image_name="${1}"

  if [ "$(strstr "${image_name}" "/")" == "0" ]; then
    image_name="library/${image_name}"
  fi

  version="$(curl https://hub.docker.com/v2/repositories/"${image_name}"/tags 2>/dev/null  | jq -r '.results[].name' | tr "\n" ' ')"

  latest=$(echo "${version}" | tr ' ' '\n' | while read item; do
    if [ -n "${item}" ] && [ "$(expr "${item}" : '^[0-9\.\-]*$')" -gt 0 ] ; then
      echo "${item}"
      break;
    fi
  done)

  if [ -z "${latest}" ]; then
    latest="-1"
  fi
  echo "${latest}"
}

########################################################################################################################
# DEFAULT PARAMETERS
########################################################################################################################
default_gitlab_target_package_fqn="sameersbn/gitlab:13.6.2"
default_gitlab_target_package_download_size=940

# let fetch latest tag from dockerhub and make it default
latest_gitlab_target_package_version="$(get_latest_version_number_from_dockerhub "sameersbn/gitlab")"
if [ "${latest_gitlab_target_package_version}" != "-1" ]; then
  gitlab_target_package_name=$(echo "${default_gitlab_target_package_fqn}" | cut -f1 -d:)
  default_gitlab_target_package_fqn="${gitlab_target_package_name}:${latest_gitlab_target_package_version}"
fi

default_postgresql_target_package_fqn="sameersbn/postgresql:11-20200524"
default_postgresql_target_package_download_size=100

default_redis_target_package_fqn="redis:5.0.9"
default_redis_target_package_download_size=29

gitlab_mod_maintainer="Juri Boxberger"
gitlab_mod_maintainer_url="https://github.com/jboxberger/synology-gitlab"

########################################################################################################################
# PARAMETER HANDLING
########################################################################################################################
for i in "$@"
do
    case ${i} in
        -gv=*|--gitlab-fqn=*)
            gitlab_target_package_fqn="${i#*=}"
        ;;
        -gs=*|--gitlab-download-size=*)
            gitlab_target_package_download_size="${i#*=}"
        ;;
        -pv=*|--postgresql-fqn=*)
            postgresql_target_package_fqn="${i#*=}"
        ;;
        -ps=*|--postgresql-download-size=*)
            postgresql_target_package_download_size="${i#*=}"
        ;;
        -rv=*|--redis-fqn=*)
            redis_target_package_fqn="${i#*=}"
        ;;
        -rs=*|--redis-download-size=*)
            redis_target_package_download_size="${i#*=}"
        ;;
        -v=*|--spk-version=*)
            spk_version="${i#*=}"
        ;;
        --docker-no-autopull)
            docker_no_autopull=1
        ;;
        --docker-no-autoclean)
            docker_no_autoclean=1
        ;;
        *)
            # unknown option
        ;;
    esac
    shift
done

if [ -z "${gitlab_target_package_fqn}" ] || [ -z "${postgresql_target_package_fqn}" ] || [ -z "${redis_target_package_fqn}" ]; then
  echo "============================================================================================================"
  echo " Please provide the full qualified docker container name from dockerhub.com or version number"
  echo "============================================================================================================"
  if [ -z "${gitlab_target_package_fqn}" ]; then
    read -ep "GitLab [default ${default_gitlab_target_package_fqn}]: " -i "${latest_gitlab_target_package_version}" gitlab_target_package_fqn
    if [ -z "${gitlab_target_package_fqn}" ]; then
      gitlab_target_package_fqn=${default_gitlab_target_package_fqn}
    else
      # check if version number only and attach image name
      if [ $(echo "${gitlab_target_package_fqn}" | sed 's/^[0-9\.-]*//' | wc -c) -eq 1 ]; then
        gitlab_target_package_fqn="${gitlab_target_package_name}:${gitlab_target_package_fqn}"
      fi
    fi
  fi

  if [ -z "${postgresql_target_package_fqn}" ]; then
    read -ep "Postgres [default ${default_postgresql_target_package_fqn}]: " postgresql_target_package_fqn
    if [ -z "${postgresql_target_package_fqn}" ]; then
      postgresql_target_package_fqn=${default_postgresql_target_package_fqn}
    fi
  fi

  if [ -z "${redis_target_package_fqn}" ]; then
    read -ep "Redis [default ${default_redis_target_package_fqn}]: " redis_target_package_fqn
    if [ -z "${redis_target_package_fqn}" ]; then
      redis_target_package_fqn=${default_redis_target_package_fqn}
    fi
  fi
fi

if [ -z "${gitlab_target_package_download_size}" ]; then
  gitlab_target_package_download_size=${default_gitlab_target_package_download_size}
fi
if [ -z "${postgresql_target_package_download_size}" ]; then
  postgresql_target_package_download_size=${default_postgresql_target_package_download_size}
fi
if [ -z "${redis_target_package_download_size}" ]; then
  redis_target_package_download_size=${default_redis_target_package_download_size}
fi

########################################################################################################################
# PROCESS VARIABLES
########################################################################################################################
gitlab_target_package_name=$(echo "${gitlab_target_package_fqn}" | cut -f1 -d:)
gitlab_target_package_version=$(echo "${gitlab_target_package_fqn}" | cut -f2 -d:)
gitlab_target_package_name_escaped=$(echo "${gitlab_target_package_name}" | tr '/' '-')

postgresql_target_package_name=$(echo "${postgresql_target_package_fqn}" | cut -f1 -d:)
postgresql_target_package_version=$(echo "${postgresql_target_package_fqn}" | cut -f2 -d:)
postgresql_target_package_name_escaped=$(echo "${postgresql_target_package_name}" | tr '/' '-')

redis_target_package_name=$(echo "${redis_target_package_fqn}" | cut -f1 -d:)
redis_target_package_version=$(echo "${redis_target_package_fqn}" | cut -f2 -d:)
redis_target_package_name_escaped=$(echo "${redis_target_package_name}" | tr '/' '-')

########################################################################################################################
# VARIABLES
########################################################################################################################
base_package_url="https://global.download.synology.com/download/Package/spk/Docker-GitLab/13.6.2-0068/Docker-GitLab-x64-13.6.2-0068.spk"
base_package_filename="${base_package_url##*/}"
base_package_name="${base_package_filename%.*}"
base_package_version="$( echo "${base_package_name}" | grep -P "([0-9]{1,2}[.][0-9]{1,2}[.]{0,1}[0-9]{0,2})" -o )"

project_name="synology-gitlab"
current_dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
download_dir="download"
docker_dir="docker"
project_dir="source/${project_name}"
target_dir="build/${project_name}"

########################################################################################################################
# INIT
########################################################################################################################
if [ -d "${project_dir}" ]; then
    rm -rf "${project_dir}"
fi

mkdir -p "${project_dir}"
mkdir -p "${project_dir}"/package

if ! [ -d "${download_dir}" ]; then
    mkdir -p "${download_dir}"
fi

if ! [ -d "${target_dir}" ]; then
    mkdir -p "${target_dir}"
fi

if ! [ -d "${docker_dir}" ]; then
    mkdir -p "${docker_dir}"
fi

########################################################################################################################
# CHECK & DWONLOAD DOCKER IMAGES
########################################################################################################################
if [ ${docker_no_autopull} -eq 1 ]; then
  download_docker_image_interactive "${gitlab_target_package_name}" "${gitlab_target_package_version}" "${docker_dir}"
  download_docker_image_interactive "${postgresql_target_package_name}" "${postgresql_target_package_version}" "${docker_dir}"
  download_docker_image_interactive "${redis_target_package_name}" "${redis_target_package_version}" "${docker_dir}"
else
  download_docker_image "${gitlab_target_package_name}" "${gitlab_target_package_version}" "${docker_dir}"
  download_docker_image "${postgresql_target_package_name}" "${postgresql_target_package_version}" "${docker_dir}"
  download_docker_image "${redis_target_package_name}" "${redis_target_package_version}" "${docker_dir}"
fi

########################################################################################################################
# INITIALIZE BASE PACKAGE
########################################################################################################################
if ! [ -f "${download_dir}"/${base_package_filename} ]; then
    cd "${download_dir}" || exit
    curl -L -J -O ${base_package_url}
    cd "${current_dir}"  || exit
fi

tar xf "${download_dir}/${base_package_filename}" -C "${project_dir}"
tar xf "${project_dir}/package.tgz" -C "${project_dir}/package"

rm "${project_dir}/package.tgz"
rm "${project_dir}/syno_signature.asc"

synology_gitlab_config="${project_dir}/package/config/synology_gitlab"
synology_gitlab_postgresql_config="${project_dir}/package/config/synology_gitlab_postgresql"
redis_config="${project_dir}/package/config/synology_gitlab_redis"

#fix json to be able to work with jq
sed -i -e "s/:__HTTP_PORT__,/:\"__HTTP_PORT__\",/g" "${project_dir}/package/config/synology_gitlab"
sed -i -e "s/:__SSH_PORT__,/:\"__SSH_PORT__\",/g" "${project_dir}/package/config/synology_gitlab"
sed -i -e "s/:\"pg_trgm\"/:\"pg_trgm,btree_gist\"/g" "${project_dir}/package/config/synology_gitlab_postgresql"

gitlab_base_package_fqn=$(jq '.image' <"${synology_gitlab_config}" | tr -d '"')
gitlab_base_package_name=$(echo "${gitlab_base_package_fqn}" | cut -f1 -d:)
gitlab_base_package_version=$(echo "${gitlab_base_package_fqn}" | cut -f2 -d:)

postgresql_base_package_fqn=$(jq '.image' <${synology_gitlab_postgresql_config} | tr -d '"')
postgresql_base_package_name=$(echo ${postgresql_base_package_fqn} | cut -f1 -d:)
postgresql_base_package_version=$(echo ${postgresql_base_package_fqn} | cut -f2 -d:)

redis_base_package_fqn=$(jq '.image' <${redis_config} | tr -d '"')
redis_base_package_name=$(echo ${redis_base_package_fqn} | cut -f1 -d:)
redis_base_package_version=$(echo ${redis_base_package_fqn} | cut -f2 -d:)

########################################################################################################################
# MODIFY PACKAGE VERSIONS
########################################################################################################################
jq -c --arg image "${gitlab_target_package_name}:${gitlab_target_package_version}"  '.image=$image' <"${synology_gitlab_config}" >"${synology_gitlab_config}.out" && mv "${synology_gitlab_config}.out" "${synology_gitlab_config}"
jq -c '.is_package=false' <"${synology_gitlab_config}" >"${synology_gitlab_config}.out" && mv "${synology_gitlab_config}.out" "${synology_gitlab_config}"

jq -c --arg image "${postgresql_target_package_name}:${postgresql_target_package_version}"  '.image=$image' <${synology_gitlab_postgresql_config} >${synology_gitlab_postgresql_config}".out" && mv ${synology_gitlab_postgresql_config}".out" ${synology_gitlab_postgresql_config}
jq -c '.is_package=false' <${synology_gitlab_postgresql_config} >${synology_gitlab_postgresql_config}".out" && mv ${synology_gitlab_postgresql_config}".out" ${synology_gitlab_postgresql_config}

jq -c --arg image "${redis_target_package_name}:${redis_target_package_version}"  '.image=$image' <${redis_config} >${redis_config}".out" && mv ${redis_config}".out" ${redis_config}
jq -c '.is_package=false' <${redis_config} >${redis_config}".out" && mv ${redis_config}".out" ${redis_config}

########################################################################################################################
# SET DEFAULT ENV VARS
########################################################################################################################
env_default="${PWD}/env_default"
if [ -s "${env_default}" ]
then
    i=0
    tmp_keys=$(jq '.env_variables[].key' <"${synology_gitlab_config}" | tr -d '"')
    while read line
    do
        keys[${i}]="${line}"
        (( i++ ))
    done <<< "${tmp_keys[@]}"

    while read LINE;
    do
        key=$(echo "${LINE}" | cut -f1 -d=)
        value=$(echo "${LINE}" | cut -f2 -d=)
        value=$(echo "${value}" | tr -d '\r') # trim \r on line-end
        in_array "${key}" "${keys[@]}"
        if [ $? == 1 ]; then
            index=$(echo "${keys[@]/${key}//}" | cut -d/ -f1 | wc -w | tr -d ' ')
            jq -c ".env_variables[${index}].value=\"${value}\""  <"${synology_gitlab_config}" >"${synology_gitlab_config}.out" && mv "${synology_gitlab_config}.out" "${synology_gitlab_config}"
        else
            jq -c ".env_variables += [{\"key\" : \"${key}\", \"value\" : \"${value}\"}]"  <"${synology_gitlab_config}" >"${synology_gitlab_config}.out" && mv "${synology_gitlab_config}.out" "${synology_gitlab_config}"
        fi
    done < "${env_default}"
fi

########################################################################################################################
# Add Custom Content
########################################################################################################################
if [ -d "overwrite/${project_name}" ]; then
    cp -Rf "overwrite/${project_name}/"* "source/${project_name}/"
fi

########################################################################################################################
# UPDATE INFO FILE
########################################################################################################################
sed -i -e "/^version=/s/=.*/=\"${gitlab_target_package_version}-${spk_version}\"/" "${project_dir}/INFO"
sed -i -e "/^distributor=/s/=.*/=\"Synology Inc. mod by ${gitlab_mod_maintainer}\"/" "${project_dir}/INFO"
echo "distributor_url=\"${gitlab_mod_maintainer_url}\"" >> "${project_dir}/INFO"

########################################################################################################################
# UPDATE SCRIPT FILES
########################################################################################################################
sed -i -e "s|${gitlab_base_package_fqn}|${gitlab_target_package_fqn}|g" "${project_dir}/scripts/postuninst"
sed -i -e "s|${postgresql_base_package_fqn}|${postgresql_target_package_fqn}|g" "${project_dir}/scripts/postuninst"
sed -i -e "s|${redis_base_package_fqn}|${redis_target_package_fqn}|g" "${project_dir}/scripts/postuninst"

sed -i -e "s|^\s*\(SIZE_GITLAB\s*=\s*\).*\$|\1${gitlab_target_package_download_size}|g" "${project_dir}/scripts/postinst"
sed -i -e "s|^\s*\(SIZE_POSTGRESQL\s*=\s*\).*\$|\1${postgresql_target_package_download_size}|g" "${project_dir}/scripts/postinst"
sed -i -e "s|^\s*\(SIZE_REDIS\s*=\s*\).*\$|\1${redis_target_package_download_size}|g" "${project_dir}/scripts/postinst"

sed -i -e "s|${gitlab_base_package_name} ${gitlab_base_package_version}|${gitlab_target_package_name} ${gitlab_target_package_version}|g" "${project_dir}/scripts/postinst"
sed -i -e "s|${postgresql_base_package_name} ${postgresql_base_package_version}|${postgresql_target_package_name} ${postgresql_target_package_version}|g" "${project_dir}/scripts/postinst"
sed -i -e "s|${redis_base_package_name} ${redis_base_package_version}|${redis_target_package_name} ${redis_target_package_version}|g" "${project_dir}/scripts/postinst"

########################################################################################################################
# INJECT HOOKS, CODE AND DATA
########################################################################################################################
echo '. "$(dirname $0)"/common_custom' >> "${project_dir}/scripts/common"
sed -i '/. "$(dirname "$0")"\/common/a . "$(dirname "$0")"\/preupgrade_custom' "${project_dir}/scripts/preupgrade"
sed -i 's/\/var\/packages\/Docker\/target\/tool\/helper \\/RestoreCustomEnvironmentVariables\nRestoreContainerPorts\n\n&/' "${project_dir}/scripts/postinst"
sed -i '/rm "$ETC_PATH"\/config/a\\trm "$ETC_PATH"\/config_custom\n\trm "$ETC_PATH"\/config_container_ports' "${project_dir}/scripts/postuninst"

########################################################################################################################
# COPY docker images
########################################################################################################################
mkdir -p "${project_dir}/package/docker"
if [ -f "docker/${gitlab_target_package_name_escaped}-${gitlab_target_package_version}.tar.xz" ]; then
    cp -rf "docker/${gitlab_target_package_name_escaped}-${gitlab_target_package_version}.tar.xz" "${project_dir}/package/docker/gitlab.tar.xz"
fi
if [ -f "docker/${postgresql_target_package_name_escaped}-${postgresql_target_package_version}.tar.xz" ]; then
    cp -rf "docker/${postgresql_target_package_name_escaped}-${postgresql_target_package_version}.tar.xz" "${project_dir}/package/docker/postgresql.tar.xz"
fi
if [ -f "docker/${redis_target_package_name_escaped}-${redis_target_package_version}.tar.xz" ]; then
    cp -rf "docker/${redis_target_package_name_escaped}-${redis_target_package_version}.tar.xz" "${project_dir}/package/docker/redis.tar.xz"
fi

########################################################################################################################
# PACKAGE BUILD
########################################################################################################################

# compress package dir
cd "${project_dir}/package/" && tar -zcf "../package.tgz" * && cd ../../../
rm -rf "${project_dir}/package/"

EXTRACTSIZE=$(du -k --block-size=1KB "${project_dir}/package.tgz" | cut -f1)
sed -i -e "/^extractsize=/s/=.*/=\"${EXTRACTSIZE}\"/" "${project_dir}/INFO"

# create spk-name
new_file_name="${project_name}-stock-aio-${gitlab_target_package_version}-${spk_version}.spk"

cd "${project_dir}/" && tar --format=gnu -cf "../../${target_dir}/${new_file_name}" * && cd ../../
