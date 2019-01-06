#!/bin/bash
IS_DEBUG=""

########################################################################################################################
# PARAMETER HANDLING
########################################################################################################################
for i in "$@"
do
    case $i in
        --debug)
            IS_DEBUG="--debug"
        ;;
        *)
            # unknown option
        ;;
    esac
    shift
done

gitlab_package_name="sameersbn/gitlab"
postgresql_package_name="sameersbn/postgresql"
redis_package_name="redis"
spk_version=0053

# https://microbadger.com/images/sameersbn/gitlab
declare -A versions;      declare -a orders;
#versions["11.0.4"]="939"; orders+=( "11.0.4" )
#versions["11.4.0"]="712"; orders+=( "11.4.0" )
#versions["11.5.0"]="725"; orders+=( "11.5.0" )
#versions["11.5.1"]="729"; orders+=( "11.5.1" )
#versions["11.5.3"]="732"; orders+=( "11.5.3" )
#versions["11.6.0"]="780"; orders+=( "11.6.0" )
versions["11.6.2"]="777"; orders+=( "11.6.2" )

for i in "${!orders[@]}"
do
    gitlab_version=${orders[$i]}
    gitlab_size=${versions[${orders[$i]}]}
    gitlab_package_fqn=$gitlab_package_name:$gitlab_version

    postgresql_version="10"
    postgresql_size="76"
    postgresql_package_fqn=$postgresql_package_name:$postgresql_version

    redis_version="3.2.6"
    redis_size="29"
    redis_package_fqn=$redis_package_name:$redis_version

    echo "building $gitlab_package_fqn ("$gitlab_size"MB) with $postgresql_package_fqn ("$postgresql_size"MB), $redis_package_fqn ("$redis_size"MB)"
    ./build.sh --gitlab-fqn=$gitlab_package_fqn --gitlab-download-size=$gitlab_size \
       --postgresql-fqn=$postgresql_package_fqn --postgresql-download-size=$postgresql_size \
       --redis-fqn=$redis_package_fqn --redis-download-size=$redis_size \
       --spk-version=$spk_version \
       "$IS_DEBUG"
done
