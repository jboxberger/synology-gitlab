## synology-gitlab

This is an upgraded and improved GitLab package which uses the stock Synology Package from [Synology Repo](https://www.synology.com/de-de/dsm/packages/Docker-GitLab) and can be installed over the original package. 

**Download Gitlab 11.9.5-0053 SPK**: [here](https://github.com/jboxberger/synology-gitlab/releases)  

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
| -             | 11.5.3-0053 | ok                 |
| -             | 11.6.0-0053 | ok                 |
| -             | 11.6.2-0053 | ok                 |
| -             | 11.6.5-0053 | ok                 |
| -             | 11.7.0-0053 | ok                 |
| -             | 11.7.3-0053 | ok                 |
| -             | 11.7.5-0053 | ok                 |
| -             | 11.8.0-0053 | ok                 |
| -             | 11.9.5-0053 | ok                 |

##### Update Stock 9.4.4-0050 to Mod
| Prev. Version | New Version | Status             |
|---------------|-------------|--------------------|
| 9.4.4-0050    | 11.0.4-0053 | ok                 |
| 9.4.4-0050    | 11.5.1-0053 | ok                 |
| 9.4.4-0050    | 11.5.3-0053 | ok                 |
| 9.4.4-0050    | 11.6.0-0053 | ok                 |
| 9.4.4-0050    | 11.6.2-0053 | ok                 |
| 9.4.4-0050    | 11.6.5-0053 | ok                 |
| 9.4.4-0050    | 11.7.0-0053 | ok                 |
| 9.4.4-0050    | 11.7.3-0053 | ok                 |
| 9.4.4-0050    | 11.7.5-0053 | ok                 |
| 9.4.4-0050    | 11.8.0-0053 | ok                 |
| 9.4.4-0050    | 11.9.5-0053 | ok                 |

##### Update Stock 11.0.4-0053 to Mod
| Prev. Version | New Version | Status             |
|---------------|-------------|--------------------|
| 11.0.4-0053   | 11.0.4-0053 | ok                 |
| 11.0.4-0053   | 11.5.1-0053 | ok                 |
| 11.0.4-0053   | 11.5.3-0053 | ok                 |
| 11.0.4-0053   | 11.6.0-0053 | ok                 |
| 11.0.4-0053   | 11.6.2-0053 | ok                 |
| 11.0.4-0053   | 11.6.5-0053 | ok                 |
| 11.0.4-0053   | 11.7.0-0053 | ok                 |
| 11.0.4-0053   | 11.7.3-0053 | ok                 |
| 11.0.4-0053   | 11.7.5-0053 | ok                 |
| 11.0.4-0053   | 11.8.0-0053 | ok                 |
| 11.0.4-0053   | 11.9.5-0053 | ok                 |

##### Update between Mod Packages
| Prev. Version | New Version | Status             |
|---------------|-------------|--------------------|
| 11.0.4-0053   | 11.5.1-0053 | ok                 |
| 11.5.1-0053   | 11.5.3-0053 | ok                 |
| 11.5.3-0053   | 11.6.0-0053 | ok                 |
| 11.6.0-0053   | 11.6.2-0053 | ok                 |
| 11.6.2-0053   | 11.6.5-0053 | ok                 |
| 11.6.5-0053   | 11.7.0-0053 | ok                 |
| 11.7.0-0053   | 11.7.3-0053 | ok                 |
| 11.7.3-0053   | 11.7.5-0053 | ok                 |
| 11.7.5-0053   | 11.8.0-0053 | ok                 |
| 11.8.0-0053   | 11.9.5-0053 | ok                 |

# Migration

### from synology-gitlab-jboxberger package to this package
Migration only works within a version. restoring a backup from version 11.5.0 to 11.5.1 or from 11.5.1 to 11.5.0 will NOT work
  
| Prev. Version | New Version | Status                 |
|---------------|-------------|------------------------|
| 11.0.4-0101   | 11.0.4-0053 | full migration needed* |
| 11.4.0-0102   | 11.4.0-0053 | full migration needed* |
| 11.5.1-0102   | 11.5.1-0053 | full migration needed* |
```
# migration synology-gitlab-jboxberger to synology-gitlab

# 1. create backup and save it from deletion 
  sudo mkdir /volume1/docker/gitlab-backup
  sudo /usr/local/bin/docker exec -it synology_gitlab bash -c "sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production"
  sudo cp -p /volume1/docker/gitlab/backups/*_gitlab_backup.tar /volume1/docker/gitlab-backup

# 2. uninstall currently installed giltab package (do *NOT* Remove GitLab data) - save database password (required for rollback).

# 3. move old gitlab data out of the way.
  sudo mv /volume1/docker/gitlab /volume1/docker/gitlab.backup
  sudo mv /volume1/docker/gitlab-db /volume1/docker/gitlab-db.backup

# 4. install the synology-gitlab package with the same version as the prevous synology-gitlab-jboxberger package.

# 5. Restore the backup files and gitlab content 
  sudo cp -p /volume1/docker/gitlab-backup/*_gitlab_backup.tar /volume1/docker/gitlab/gitlab/backups 

# (file_name)'1547251748_2019_01_12_11.5.0_gitlab_backup.tar' => <backup_name>'1547251748_2019_01_12_11.5.0'
  sudo /usr/local/bin/docker exec -it synology_gitlab bash -c "sudo -u git -H bundle exec rake gitlab:backup:restore RAILS_ENV=production BACKUP=<backup_name>"

# 6. Test your environment as carefull as possible. Take time for testing. 
# Depending on your testing result plseas continue with 6.1 or 6.2 
# If you get a 422 GitLab error, please clear the whole broswer cache including data and cookies.

# 6.1 Oh...Oh...! Something is broken... Restore11!
# Uninstall currently installed synology-gitlab package (check delete database)
  sudo mv /volume1/docker/gitlab.backup /volume1/docker/gitlab
  sudo mv /volume1/docker/gitlab-db.backup /volume1/docker/gitlab-db
# Now install the synology-gitlab-jboxberger (same version as installed prevously). 
#   Check "Use existing data"!
#   Use the same database passowrd you have used on the prevous installation!

# 6.2 Yay it works!!! I've backed everything up in case i miss something later! Now Cleanup.
  sudo rm -rf /volume1/docker/gitlab-backup
  sudo rm -rf /volume1/docker/gitlab.backup
  sudo rm -rf /volume1/docker/gitlab-db.backup
  
###################################################################################################################
If shit hits the fan! Call 911 or write me an email. I try to help as good i can. 
```

### from old modified synology-gitlab package
| Prev. Version | New Version | Status               |
|---------------|-------------|----------------------|
| 10.1.4        | 11.0.4-0053 | modification needed* |
| 10.1.4        | 11.5.1-0053 | modification needed* |
| 10.1.4        | 11.5.3-0053 | modification needed* |
|---------------|-------------|----------------------|
| 10.2.5        | 11.0.4-0053 | modification needed* |
| 10.2.5        | 11.5.1-0053 | modification needed* |
| 10.2.5        | 11.5.3-0053 | modification needed* |

```
# *modification - we need to restore the naming scheme from the stock package BEFORE the update

sudo vi /var/packages/Docker-GitLab/INFO
change the line: version="10.x.x" to version="10.x.x-0050"

sudo vi /var/packages/Docker-GitLab/etc/config
change the line: VERSION="10.x.x" to VERSION="0050"
```

### from maria_db to postgres_sql
This is the snippet how the synology-gitlab original package converts from mariadb to postgres, just in case you need
it otherwise. You find the db_converter.py in the .spk file, just extract it like a zip file and watch for the scripts
folder. 
```
#!/bin/sh
MYSQLDUMP_BIN="/usr/local/mariadb10/bin/mysqldump"
DOCKER_HOST=$(ip address show docker0 | grep inet | awk '{print $2}' | cut -f1 -d/ | head -n 1)
DB_USER="gitlab_user"
DB_PASS="<database_password>"
DB_NAME="gitlab"
MYSQL_TMP="/tmp/mysql_tmp.sql"
POSTGRESQL_TMP="/tmp/postgresql_tmp.sql"
PREUPGRADE_CHECK_DB_CONVERT="/var/packages/Docker-GitLab/scripts/preupgrade_check_db_convert/"
POSTGRESQL_NAME=synology_gitlab_postgresql

"$MYSQLDUMP_BIN" --compatible=postgresql --default-character-set=utf8 --hex-blob --host="$host" -u "$DB_USER" --password="$DB_PASS" "$DB_NAME" > "$MYSQL_TMP"
/bin/python "$PREUPGRADE_CHECK_DB_CONVERT/db_converter.py" "$MYSQL_TMP" "$POSTGRESQL_TMP"
if [ "$?" -ne 0 ]; then
	logger -p 0 "$PKG_NAME: preupgrade fail to convert db."
	exit 1
fi
docker cp "$POSTGRESQL_TMP" "$POSTGRESQL_NAME":/gitlab.psql
rm "$MYSQL_TMP" "$POSTGRESQL_TMP"

docker stop synology_gitlab
docker exec "$POSTGRESQL_NAME" psql -U "postgres" -c "DROP DATABASE IF EXISTS $DB_NAME;"
docker exec "$POSTGRESQL_NAME" psql -U "postgres" -c "CREATE DATABASE $DB_NAME;"
docker exec "$POSTGRESQL_NAME" psql -U "postgres" -c "GRANT ALL privileges ON DATABASE $DB_NAME TO $DB_USER;"
docker exec "$POSTGRESQL_NAME" psql -U "$DB_USER" -v "ON_ERROR_STOP=1" -f /gitlab.psql -d "$DB_NAME"
docker start synology_gitlab
```
