#synology-gitlab
Updated an improved Original Synology Package from 
https://www.synology.com/de-de/dsm/app_packages/Docker-GitLab

#Packages used:  
The following docker images will be downloaded during the installation. This will take some time so please be ptaient.

sameersbn/gitlab:8.x.x (about 300MB) https://hub.docker.com/r/sameersbn/gitlab/   
sameersbn/redis:latest (about 66MB)  https://hub.docker.com/r/sameersbn/redis/  

#Supported Architectures
Since i can't test all architectures i had to make a choice which i can cover or which i expect to work. If your architecture is not in 
this list so please feel free to contact me and we can give it a try.
 
For now this package should work on this architectures: **x86 avoton bromolow cedarview braswell kvmx64**

You can check the architecture of your device here: https://github.com/SynoCommunity/spksrc/wiki/Architecture-per-Synology-model

#Updates
**Please be patient during the Update process**. Updates may take several minutes because the 
new docker Image needs to be downloaded from the docker-hub. Depending on your internet connection 
the download of approximate 350MB can take some time. The first docker container boot up - after 
installation/update - takes some minutes because GitLab needs to migrate tha Database first, you 
can see the status in the GitLab container log (DSM docker backend). The Update is complete when 
the CPU begins to idle.    

- **2016-03-05** - sameersbn/gitlab:8.16.6 (305.1MB)
- **2016-02-05** - sameersbn/gitlab:8.16.3 (303.3MB)
- **2016-01-25** - sameersbn/gitlab:8.15.4 (314.8MB)
- **2016-01-08** - sameersbn/gitlab:8.15.2 (298.3MB)
- **2016-12-03** - sameersbn/gitlab:8.14.1 (313.9MB)
- **2016-11-17** - sameersbn/gitlab:8.13.5 (308.7MB)
- **2016-10-30** - sameersbn/gitlab:8.13.1 (308.6MB)
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
- DSM 6.1 takes the old Gitlab icon from the original package instead the updated icon from from my package.
- DSM 6.0-7321 breaks the docker container. You can fix it by reinstalling the synology-gitlab package (without changing any settings)
- When you have troubles updating, update again an re-enter the gitlab database credentials.
- If you have trouble removing old images you can try this. Fist stop all useless images. Then login with ssh as root 
  on your synology and enter this command
  
  docker rmi $(docker images -q --filter dangling=true)
  
  If the old images are gone you can reinstall the synology package and everything should work fine. If it doesn't
  help, you can uninstall the synology package (keeping all your data) and reinstall the package again (please don't
  forget to save your database credentials first). 
- On a new Gitlab (DB) Install, for unknown reasons the gitlab install routine stops with an error and fails to add 
  the default 'root' user. 
  ```
  /home/git/gitlab/lib/tasks/gitlab/setup.rake:17:in `setup_db'
  /home/git/gitlab/lib/tasks/gitlab/setup.rake:4:in `block (2 levels) in &lt;top (required)&gt;'
  Tasks: TOP =&gt; db:schema:load
  (See full trace by running task with --trace)
  ```
  
  You can login to your database and insert the user manually with this query:
  ```sql
    INSERT into gitlab.users (id, email, encrypted_password, name, admin, authentication_token, username, state, notification_email, confirmation_token, confirmed_at, password_expires_at, created_at ) VALUES (
        1,																	
        'root@gitlab.com',													
        '$2a$10$tZ0VSv4BpRut2sXQVjJskO/VAX539vqeBEQJ1yc0nc9H0xsGMc/42',		
        'root',																
        1,																	
        'hZ2R2V791aKYNu34DEGJ',												
        'root',																 
        'active',															
        'root@gitlab.com', 													
        'Wt1matyrmTsdvc7LJk2E',                                         	
        '2015-12-29 15:55:16',                                          	
        '2015-01-01 01:00:00',                                              
        '2015-01-01 01:00:00'												
    );
  ```
  
  Now you can login with the default credentials 'root' / '5iveL!fe'. I highly recommend to add a new user and delete this "dummy" user
  because of the public authentication_token.
  
# HowTo's

## Backup all my Gitlab data
First go to the Packet Manager in your DSM and stop the Gitlab Package.

**1) Save your GitLab Credentials**
- go to Docker App in you DSM
- Select Container
- choose your synology_gitlab container
- click settings button (above) and export your settings, alternatively you can click on Details and backup your environment variables by hand  
- the **most important** variables are GITLAB_SECRETS_DB_KEY_BASE, GITLAB_SECRETS_SECRET_KEY_BASE, Database Credentials to get the DB Dump  

**2) Save Database**
- login via ssh 
- complete the following command from your settings you saved before in the first step

  ```markdown
    mysqldump -h localhost -u <DB_USER> -p"<DB_PASS>" <DB_NAME> > /volume1/anyfolder/gitlab_database_dump.sql
  ```

**3) Save Data**
- backup folder /volume1/docker/gitlab

Now you should be save and be able to restore your whole installation even if something went really wrong.