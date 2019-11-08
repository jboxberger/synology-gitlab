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
spk_version=0055

# https://microbadger.com/images/sameersbn/gitlab
declare -A versions;      declare -a orders;
#versions["11.11.0"]="899"; orders+=( "11.11.0" )
#versions["12.2.5"]="909"; orders+=( "12.2.5" )
#versions["12.3.3"]="955"; orders+=( "12.3.3" )
#versions["12.3.5"]="955"; orders+=( "12.3.5" )
#versions["12.4.1"]="991"; orders+=( "12.4.1" )
versions["12.4.2"]="992"; orders+=( "12.4.2" )

for i in "${!orders[@]}"
do
    gitlab_version=${orders[$i]}
    gitlab_size=${versions[${orders[$i]}]}
    gitlab_package_fqn=$gitlab_package_name:$gitlab_version

    postgresql_version="10"
    postgresql_size="76"
    postgresql_package_fqn=$postgresql_package_name:$postgresql_version

    redis_version="4.0.14"
    redis_size="29"
    redis_package_fqn=$redis_package_name:$redis_version

    echo "building $gitlab_package_fqn ("$gitlab_size"MB) with $postgresql_package_fqn ("$postgresql_size"MB), $redis_package_fqn ("$redis_size"MB)"
    ./build.sh --gitlab-fqn=$gitlab_package_fqn --gitlab-download-size=$gitlab_size \
       --postgresql-fqn=$postgresql_package_fqn --postgresql-download-size=$postgresql_size \
       --redis-fqn=$redis_package_fqn --redis-download-size=$redis_size \
       --spk-version=$spk_version \
       "$IS_DEBUG"
done
