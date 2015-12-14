# synology-gitlab
Updated an improved Original Synology Package from https://www.synology.com/de-de/dsm/app_packages/Docker-GitLab

Packages used:  
https://hub.docker.com/r/sameersbn/gitlab/  
https://hub.docker.com/r/sameersbn/redis/  

Improvements
- Updated Redis to latest
- Gitlab Update to 8.2.3
- Increased UNICORN_TIMEOUT to 180s

The following docker images will be downloaded during the installation. This will take some time so please be ptaient.
sameersbn/gitlab:8.2.3 (249.7MB)  
sameersbn/redis:latest (66MB)
