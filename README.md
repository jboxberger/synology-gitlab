# synology-gitlab
Updated an improved Original Synology Package from 
https://www.synology.com/de-de/dsm/app_packages/Docker-GitLab

# Packages used:  
The following docker images will be downloaded during the installation. This will take some time so please be ptaient.

sameersbn/gitlab:8.x.x (about 300MB) https://hub.docker.com/r/sameersbn/gitlab/   
sameersbn/redis:latest (about 66MB)  https://hub.docker.com/r/sameersbn/redis/  

#Updates
**Please be patient during the Update process**. Updates may take several minutes because the 
new docker Image needs to be downloaded from the docker-hub. Depending on your internet connection 
the download of approximate 350MB can take some time. The first docker container boot up - after 
installation/update - takes some minutes because GitLab needs to migrate tha Database first, you 
can see the status in the GitLab container log (DSM docker backend). The Update is complete when 
the CPU begins to idle.    

- **2016-10-16** - sameersbn/gitlab:8.12.6 (307.5MB) - docker settings now enabled
- **2016-10-04** - sameersbn/gitlab:8.12.3 (308.9MB)
- **2016-09-19** - sameersbn/gitlab:8.11.6 (303.1MB)
- **2016-08-25** - sameersbn/gitlab:8.11.2 (303.0MB)
- **2016-08-25** - sameersbn/gitlab:8.11.0 (302.3MB)
- **2016-07-24** - sameersbn/gitlab:8.10.0 (293.0MB)  
- **2016-07-09** - sameersbn/gitlab:8.9.5 (287.1MB)  
- **2016-06-25** - sameersbn/gitlab:8.9.0 (284.6MB)  
- **2016-06-03** - sameersbn/gitlab:8.8.3 (290.5MB)  
- **2016-05-16** - sameersbn/gitlab:8.7.5 (279.7MB)  
- **2016-05-06** - sameersbn/gitlab:8.7.2 (279.5MB)  
- **2016-05-01** - sameersbn/gitlab:8.7.0 (274.2MB)  
- **2016-03-29** - sameersbn/gitlab:8.6.1 (270.0MB)  
- **2016-03-19** - sameersbn/gitlab:8.5.8 (268.6MB)  
- **2016-03-01** - sameersbn/gitlab:8.5.1 (268.2MB)  
- **2016-02-04** - sameersbn/gitlab:8.4.3 (267.7MB)
- **2016-01-24** - sameersbn/gitlab:8.4.0 (267.7MB)
- **2015-12-31** - sameersbn/gitlab:8.3.2 (254.3MB)
- **2015-12-14** - sameersbn/gitlab:8.2.3 (250.9MB)

#Known Problems
- DSM 6.0-7321 breaks the docker container. You can fix it by reinstalling the synology-gitlab package (without changing any settings)
- When you have troubles updating, update again an re-enter the gitlab database credentials.
- If you have trouble removing old images you can try this. Fist stop all useless images. Then login with ssh as root 
  on your synology and enter this command
  
  docker rmi $(docker images -q --filter dangling=true)
  
  If the old images are gone you can reinstall the synology package and everything should work fine. If it doesn't
  help, you can uninstall the synology package (keeping all your data) and reinstall the package again (please don't
  forget to save your database credentials first). 