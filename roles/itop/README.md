# iTop CMDB

[iTop](https://www.combodo.com/itop) is a Configuration Management Database written in PHP, developped by combodo

## Installation

The installation is not fully automatic. This ansible role will take care of creating the DB, install the app, configure PHP, httpd etc.
But you'll have to finish the setup manually by going to the /setup path.
Note : if you run iTop beind a reverse proxy, you'll have to temporarily edit web/application/utils.inc.php. In this file, the GetDefaultUrlAppRoot will return port 80 instead of 443 (because the httpd instance is running on port 80, but the client uses port 443 to contact the reverse proxy). Just change the line :

```
$iPort = isset($_SERVER['SERVER_PORT']) ? $_SERVER['SERVER_PORT'] : 80;
```

to

```
//$iPort = isset($_SERVER['SERVER_PORT']) ? $_SERVER['SERVER_PORT'] : 80;
$iPort = 443;
```

You can revert this change once the installation is done. For the installation, you need to use a MySQL account with the SUPER privilege (which is not the case of the default user created).

## Upgrade

For upgrades, there are several manual steps to be done. First, you need to grant write access to the config file

```
chmod 660 /opt/itop_1/web/conf/production/itop-config.php
```

Then go to /setup and follow the steps. Note : the upgrade needs a user with the SUPER privilege on MySQL. This is not the case of the default user created by this role for security reason. So you should use your SQL admin for the upgrade process. Once the upgrade is done, you can restrict again permissions. note during the upgrade, you'll have to fixe the URL if you're running behind a rev proxy, because iTop will force the port to be 80 !

```
chmod 660 /opt/itop_1/web/conf/production/itop-config.php
```

And edit /opt/itop_1/web/conf/env-production/itop-config.php to set back the itop_1 user and password (as it'll have the sqladmin user here)
