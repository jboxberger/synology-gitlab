## synology-gitlab

This is an upgraded and improved GitLab package which uses the stock Synology Package from [Synology Repo](https://www.synology.com/de-de/dsm/packages/Docker-GitLab) and can be installed over the original package. 

**Download latest SPK**: [here](https://github.com/jboxberger/synology-gitlab/releases)  

## Hardware Requirements:
- 1 CPU core ( 2 cores is recommended )
- 1 GB RAM ( 4GB RAM is recommended )
- 700 MB Space on your HDD

Looking for a more lightweight GIT Package with a GitLab like UI, then check my new [Gitea Synology Package](https://github.com/jboxberger/synology-gitea-jboxberger). Gitea requires only 80MB RAM and have all basic features onboard (Web UI, Git, Issues, Wiki and more).

## Additional Features
- All-In-One Installer
- restore custom ENVIRONMENT variables after update (any variable not in scripts/env_ignore)

## Supported Architectures
**x86_64**  
Since i can't test all architectures i had to make a choice which i can cover or which i expect to work. If your architecture 
is not in this list so please feel free to contact me and we can give it a try.  

You can check the architecture of your device [here](https://github.com/SynoCommunity/spksrc/wiki/Architecture-per-Synology-model) 
or [here](https://www.synology.com/en-us/knowledgebase/DSM/tutorial/General/What_kind_of_CPU_does_my_NAS_have).

# Backup
```
# backup files will be saved in gitlab/backups directory usually ( /volume1/docker/gitlab/gitlab/backups ) 
# the backup contains the config files including !PASSWORDS! be shure to keep them in an safe place!
#
# Parameters:
# RAILS_ENV => we have only "production" environment so this parameter is pretty static
# CRON=1 => Parameter supress any output. To get detailed debug information remove the parameter from command ( CRON=0 will not work )

sudo /usr/local/bin/docker exec -it synology_gitlab bash -c "sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production CRON=1" 

# yo can make the backups readyble by your DSM user but use theis only when you knwo what you're doing and do not have any
# security concerns
sudo chmod g+rw /volume1/docker/gitlab/backups/*.tar
```

# Restore
```
# restoring only works within a version. restoring a backup from version 10.1.2 to 10.1.1 or from 10.1.1 to 10.1.2 will NOT work
# only restoring from 10.1.2 to 10.1.2 will work.
#
# Parameters:
# RAILS_ENV => we have only "production" environment so this parameter is pretty static
# BACKUP => backup name (NOT filename) file: 1544961414_2018_12_16_9.4.4_gitlab_backup.tar => backup_name: 1544961414_2018_12_16_9.4.4
  
sudo /usr/local/bin/docker exec -it synology_gitlab bash -c "sudo -u git -H bundle exec rake gitlab:backup:restore RAILS_ENV=production BACKUP=1544961414_2018_12_16_9.4.4"
```

# Updates
**Always backup data before update! _Please be patient during the Update process_**.   
The first docker container boot up - after installation/update - takes some minutes because GitLab needs to migrate the 
Database first, you can see the status in the GitLab container log (DSM docker backend). __**The Update is complete when the CPU begins to idle.**__    

```
Stock: Package directly installed from Synology		
Mod: modified Gitlab Package		
```
 
### DSM 6.2-23739 Update 2

##### Clean Install
| Prev. Version | New Version | Status             |
|---------------|-------------|--------------------|
| -             | 11.0.4-0053 | ok                 |
| -             | 11.5.1-0053 | ok                 |

##### Update Stock 9.4.4-0050 to Mod
| Prev. Version | New Version | Status             |
|---------------|-------------|--------------------|
| 9.4.4-0050    | 11.0.4-0053 | ok                 |
| 9.4.4-0050    | 11.5.1-0053 | ok                 |

##### Update Stock 11.0.4-0053 to Mod
| Prev. Version | New Version | Status             |
|---------------|-------------|--------------------|
| 11.0.4-0053   | 11.0.4-0053 | ok                 |
| 11.0.4-0053   | 11.5.1-0053 | ok                 |

##### Update between Mod Packages
| Prev. Version | New Version | Status             |
|---------------|-------------|--------------------|
| 11.0.4-0053   | 11.5.1-0053 | ok                 |
