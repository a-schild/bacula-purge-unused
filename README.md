# bacula-purge-unused
Purge unused file media in bacula/bareos backups

**This version works with MySQL databases, if you use Postgresql, then please check the code first**

Usage: `./bacula-purge-unused [--debug] [--truncate] [--remove] [--error-only] [options]`

```
Options:
  --except-job N[,M...]]
      for running jobs (may affect error-only status)
 --fuzz-days N
      only report files which are more than N days beyond expiry date.
 --error-only
      only report/remove files which only contain failed jobs
 --data-directory DIR
      where data lives (default /srv/bacula/data)

Available options to configure database access:
  --database-config FILE  database connection settings
  --database-name DBNAME
  --database-dsn DSN
  --database-user USER
  --database-password PASSWORD
```

For DB configuration it is best to specify a file containing the DB connection config,
for example in `/etc/bareos/database.cf`
You have to then specify it in the command line `--database-config /etc/bareos/database.cf`

Such a file could look like this:  
```
database-dsn DBI:mysql:database=bareos;host=localhost
database-name bareos
database-host localhost
database-user bareos
database-password <my-db-password>
```

##Install
* Copy the two files on a location of your backup server, for example to `/opt/bacula-purge-unused`
* If you have a separate storage daemon server, then copy them to that server, or make sure the directory server has access to the storage file system
* Install the required perl libraries, you will need `libxml-simple-perl` and the dbi perl files for your database
* `apt-get install libxml-simple-perl` 
* create the /etc/bareos/database.cf file
* start the application

##Origins
Based on the 1.4 version of http://heim.ifi.uio.no/kjetilho/hacks/bacula-purge-unused-1.4.tar.gz
http://heim.ifi.uio.no/kjetilho/hacks/#bacula-purge-unused
