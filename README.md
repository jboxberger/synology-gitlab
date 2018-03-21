# please use the NEW [synology-gitlab-jboxberger](https://github.com/jboxberger/synology-gitlab-jboxberger) package!

* * *

[GitLab has dropped MariaDB Support.](https://docs.gitlab.com/ce/install/requirements.html#database) The 10.2.5 is the 
latest version working with MariaDB10. Any higher version Fail to migrate the database schema. This is an GitLab issue
which i can not fix and GitLab will not fix because it's not supported anymore.  

If you don't want to wait until synology releases a updated package and if you would like to have some extra Features with
a more frequent update sequence then you can use my GitLab PostgreSQL package [here](https://github.com/jboxberger/synology-gitlab-jboxberger).
You can Migrate from Stock 9.4.4-0050 or from this package 10.1.4 and 10.2.5 very easily. Hope you like it.

This package will not be updated anymore and stay for legacy reasons.   

---------------------------------------

## synology-gitlab

This is an upgraded and improved GitLab package which uses the stock Synology Package from [Synology Repo](https://www.synology.com/de-de/dsm/packages/Docker-GitLab). 

**Download latest SPK**: [here](https://github.com/jboxberger/synology-gitlab/releases)  
 
## New since 10.1.1
- All-In-One Installer
- MariaDB10 Migration
- Backup/Restore scripts
- restore custom ENVIRONMENT variables after update (any variable not in scripts/env_ignore)

## GitLab 10.5.x
Database Migration fails because of MariaDB ROW_FORMAT, waiting for fix.
 
## Supported Architectures
**x86 avoton bromolow cedarview braswell kvmx64 broadwell apollolake**  
Since i can't test all architectures i had to make a choice which i can cover or which i expect to work. If your architecture 
is not in this list so please feel free to contact me and we can give it a try.  

You can check the architecture of your device [here](https://github.com/SynoCommunity/spksrc/wiki/Architecture-per-Synology-model) 
or [here](https://www.synology.com/en-us/knowledgebase/DSM/tutorial/General/What_kind_of_CPU_does_my_NAS_have).

# Backup
```
# backup files will be saved in docker/backup directory
# the backup contains the config files including !PASSWORDS! be shure to keep them in an safe place!

sudo ./var/packages/Docker-GitLab/scripts/backup --maria-db-root-password "<root-password>"	
```
# Restore
```
# restoring to a mismatched GitLab Version (e.g. 10.1.4 backup file to 9.4.4 GitLab) my cause problems
# i highly reccommend to restore only matching backup and GitLab versions.
  
sudo ./var/packages/Docker-GitLab/scripts/restore --maria-db-root-password "<root-password>" --restore-file "2018-01-27-16-12-03-gitlab-10.1.4.tar.gz"
```

# Updates
**Always backup data before update! _Please be patient during the Update process_**.   
The first docker container boot up - after installation/update - takes some minutes because GitLab needs to migrate the 
Database first, you can see the status in the GitLab container log (DSM docker backend). __**The Update is complete when the CPU begins to idle.**__    
 
#### DSM 6.1.1-15101 
| Package Type  | Prev. Version | New Version | Status             |
|---------------|---------------|-------------|--------------------|
| Stock         | 8.17.4-0022   | 10.1.4      | incompatible       |
| Stock         | 9.4.4-0024    | 10.1.4      | ok                 |
| Stock         | 9.4.4-0050    | 10.1.4      | ok                 |
| Old           | 9.5.2         | 10.1.4      | ok                 |
| Old           | 10.0.2        | 10.1.4      | ok                 |
| Old           | 10.1.1        | 10.1.4      | ok                 |
| New           | 10.1.4        | 10.2.5      | ok                 |

#### DSM 6.1.4-15217 
| Package Type  | Prev. Version | New Version | Status             |
|---------------|---------------|-------------|--------------------|
| Stock         | 8.17.4-0022   | 10.1.4      | incompatible       |
| Stock         | 9.4.4-0024    | 10.1.4      | ok                 |
| Stock         | 9.4.4-0050    | 10.1.4      | ok                 |
| Old           | 9.5.2         | 10.1.4      | ok                 |
| Old           | 10.0.2        | 10.1.4      | ok                 |
| Old           | 10.1.1        | 10.1.4      | ok                 |
| New           | 10.1.4        | 10.2.5      | ok                 |
| New           | 10.2.5        | 10.3.x      | DB Migrate fail    |
| New           | 10.2.5        | 10.4.2      | DB Migrate fail    |
| New           | 10.2.5        | 10.5.1      | DB Migrate fail    |
| New           | 10.2.5        | 10.5.5      | DB Migrate fail    |

```
Stock: Package directly installed from Synology		
Old: Old modified Gitlab Package up to v10.1.1		
New: New modified Gitlab Package from v10.1.4		
```
