# synology-gitlab
Updated an improved Original Synology Package from https://www.synology.com/de-de/dsm/app_packages/Docker-GitLab

Packages used:  
https://hub.docker.com/r/sameersbn/gitlab/  
https://hub.docker.com/r/sameersbn/redis/  

# DSM 6.0-7321 
- DSM 6.0-7321 breaks the docker container. You can fix it by reinstalling the synology-gitlab package (without changing any settings)

# NOTE: 
- When cloning please be shure to turn off the git autocrlf, otherwise shell installation scripts may not work.
You can use this command: git config --global core.autocrlf false

#2016-08-25
- Gitlab Update to 8.11.0 - sameersbn/gitlab:8.11.0 (302.3MB)

#2016-07-24
- Gitlab Update to 8.10.0 - sameersbn/gitlab:8.10.0 (293.0MB)  

#2016-07-09
- Gitlab Update to 8.9.5 - sameersbn/gitlab:8.9.5 (287.1MB)  

#2016-06-25
- Gitlab Update to 8.9.0 - sameersbn/gitlab:8.9.0 (284.6MB)  

#2016-06-03
- Gitlab Update to 8.8.3 - sameersbn/gitlab:8.8.3 (290.5MB)  

#2016-05-16
- Gitlab Update to 8.7.5 - sameersbn/gitlab:8.7.5 (279.7MB)  

#2016-05-06
- Gitlab Update to 8.7.2 - sameersbn/gitlab:8.7.2 (279.5MB)  

#2016-05-01
- Gitlab Update to 8.7.0 - sameersbn/gitlab:8.7.0 (274.2MB)  

#2016-03-29
- Gitlab Update to 8.6.1 - sameersbn/gitlab:8.6.1 (270.0MB)  

#2016-03-19
- Gitlab Update to 8.5.8 - sameersbn/gitlab:8.5.8 (268.6MB)  

#2016-03-01
- Gitlab Update to 8.5.1 - sameersbn/gitlab:8.5.1 (268.2MB)  

#2016-02-04
Improvements
- Gitlab Update to 8.4.3 - sameersbn/gitlab:8.4.3 (267.7MB)  
NOTE: When you have troubles updating, update again an re-enter the gitlab database credentials.

#2016-01-24
Improvements
- Gitlab Update to 8.4.0 - sameersbn/gitlab:8.4.0 (267.7MB)  
- Fixed Upgrade issue: Failed to remove old Images.

If you have trouble removing old images you can try this. Fist stop all useless images. Then login with ssh as root 
on your synology and enter this command

docker rmi $(docker images -q --filter dangling=true)

If the old images are gone you can reinstall the synology package and everything should work fine. If it doesn't
help, you can uninstall the synology package (keeping all your data) and reinstall the package again (please don't
forget to save your database credentials first). 

#2015-12-31
Improvements
- Gitlab Update to 8.3.2 - sameersbn/gitlab:8.3.2 (254.3MB)  
- Added English UI
- renamed package folder spk/ to bin/
- install/updated/uninstall procces rewrite
- Feature: Uninstall and Keep Gitlab Data
- Feature: Use individual database user and password. 
- Feature: Install on existing gitlab database and files
- Note: On Update you may need to specify the Databse User "gitlab" once



#2015-12-14
Improvements
- Updated Redis to latest
- Gitlab Update to 8.2.3
- Increased UNICORN_TIMEOUT to 180s

The following docker images will be downloaded during the installation. This will take some time so please be ptaient.
sameersbn/gitlab:8.2.3 (249.7MB)  
sameersbn/redis:latest (66MB)
