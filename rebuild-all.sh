#!/bin/bash

gitlab_package_name="sameersbn/gitlab"
redis_package_name="redis"

# https://microbadger.com/images/sameersbn/gitlab
declare -A versions;      declare -a orders;
versions["10.1.4"]="667"; orders+=( "10.1.4" )
versions["10.2.2"]="711"; orders+=( "10.2.2" )
versions["10.2.5"]="713"; orders+=( "10.2.5" )

declare -A redis_sizes
redis_sizes["3.2.6"]=68
redis_sizes["3.2.11"]=41
redis_sizes["latest"]=68

for i in "${!orders[@]}"
do
    gitlab_version=${orders[$i]}
    gitlab_size=${versions[${orders[$i]}]}
    gitlab_package_fqn=$gitlab_package_name:$gitlab_version

    redis_version="3.2.11"
    redis_size=${redis_sizes[$redis_version]}
    redis_package_fqn=$redis_package_name:$redis_version

    echo "building $gitlab_package_fqn ("$gitlab_size"MB) with $redis_package_fqn ("$redis_size"MB)"
    ./build.sh --gitlab-fqn=$gitlab_package_fqn --gitlab-download-size=$gitlab_size --redis-fqn=$redis_package_fqn --redis-download-size=$redis_size --all-in-one
done
