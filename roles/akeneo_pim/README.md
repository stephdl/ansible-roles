# Akeneo PIM

[Akeneo PIM](https://www.akeneo.com/) A Product Information Management (PIM) solution is aimed to centralize all the marketing data

## Settings

Akeneo requires a few settings at the host level. Something like this
```
# This should be defined on the server which will host the database
# It's not mandatory to be on the same host as the PIM itself. But the important thing is that AKeneo PIM
# requires MySQL. It'll not work with MariaDB
mysql_engine: mysql

# Prevent an error when checking system requirements. Note that this is only for the CLI
# as web access will use it's own FPM pool
php_conf_memory_limit: 512M

# We need Elasticsearch 7. Same foir MySQL, it's not required to be on the same host
es_major_version: 7

# Define a vhost to expose the PIM. Note that this is a minimal example
# And you will most likely want to put a reverse proxy (look at the nginx role) in front of it
httpd_ansible_vhosts:
  - name: pim.example.org
    document_root: /opt/pim_1/app/public

```

## Installation
Installation should be fully automatic

## Upgrade
Major upgrades might require some manual steps, as detailed on https://docs.akeneo.com/5.0/migrate_pim/upgrade_major_version.html

