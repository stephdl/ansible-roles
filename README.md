# Ansible roles

At [Firewall Services](https://www.firewall-services.com), we use Ansible. And we use it **a lot**. Like, there's now nearly nothing we deploy manually, without it. As such we've written a lot of roles, to deploy and manage various applications. This include :

* Basic system configuration
* Authentication (eg, configure LDAP auth, or join an AD domain automatically)
* Plumber layers (like deploy a MySQL server, a PHP stack etc.)
* Authentication services (Samba4 in AD DC mode, Lemonldap::NG etc.)
* Collaborative apps (like Zimbra, Matrix, Etherpad, Seafile, OnlyOffice, Jitsi etc.)
* Monitoring tools (deploy Zabbix agent, proxy and server, Fusion Inventory agent, Graylog server)
* Web applications (GLPI, Ampache, Kanboard, Wordpress, Dolibarr, Matomo, Framadate, Dokuwiki etc.)
* Dev tools (Deploy a Gitea server)
* Security tools (OpenXPKI, Bitwareden_RS, manage SSH keys etc.)
* A lot more :-)

Most of our roles are CentOS centric, and are made to be deployed on CentOS 7 servers. Basic roles (like basic system configuration, postfix etc.) also support Debian systems, but are less tested.

Our roles are often dependent on other roles. For example, if you deploy glpi, it'll first pull all the required web and PHP stack. 

Most of the web application roles are made to run behind a reverse proxy. You can use for this the nginx (recommended) or the httpd_front role.

## how to use this

Here're the steps to make use of this. Note that this is not a complete ansible how-to, just a quick guide to use our roles. For example, it'll not explain how to make use of ansible-vault to protect sensitive informations.

* Clone the repo
```
git clone https://git.fws.fr/fws/ansible-roles.git
cd ansible-roles
```

* Create a few directories
```
mkdir {inventories,host_vars,group_vars,ssh,config}
```

* Create your SSH key. It's advised to set a passphrase to protect it
```
ssh-keygen -t rsa -b 4096 -f ssh/id_rsa
```

* Create the ansible user account on the hosts you want to manage. This can be done manually or can be automated with tools like kickstart (you can have a look at https://ks.fws.fr/el7.ks for example). The ansible user must have elevated privileges with sudo (so you have to ensure sudo is installed)
```
useradd -m ansible
mkdir ~ansible/.ssh
cat <<_EOF > ~ansible/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCwnPxF7vmJA8Jr7I2q6BNRxQIcnlFaA3O58x8532qXIox8fUdYJo0KkjpEl6pBSWGlF4ObTB04/Nks5rhv9Ew+EHO5GvavzVp5L3u8T+PP+idlLlwIERL2R632TBWVbxqvhtc813ozpaMRI7nCabgiIp8rFf4hqYJIn/RMpRdPSQaHrPHQpFEW9uHPbFYZ9+dywY88WXY+VJI1rkIU3NlOAw3GKjEd6iqiOboDl8Ld4qqc+NpqDFPeidYbk5xjKv3l/Y804tdwqO1UYC+psr983rs1Kq91jI/5xSjSQFM51W3HCpZMTzSIt4Swy+m+eqUIrInxMmw72HF2CL+PePHgmusMUBYPdBfqHIxEHEbvPuO67hLAhqH1dUDBp+0oiRSM/J/DX7K+I+jNO43/UtcvnrBjNjzAiiJEG3WRAcBAUpccOu3JHcRN5CLRB26yfLXpFRzUNCnajmdZF7qc0G5gJuy8KpUZ49VTmZmJ0Uzx1rZLaytSjHpf4e5X6F8iTQ1QmORxvCdfdsqoeod7jK384NXq+UD24Y/tEgq/eT7pl3yLCpQo4qKd/aCEBqc2bnLggVRr+WX94ojMdK35qYbdXtLsN5y6L20yde8tGtWY+nmbJzLnqVJ4TKxXKMl7q9Sdj1t7BrqQQIK3H9kP7SZRhWNP6tvNKBgKFgc/k01ldw== ansible@fws.fr
_EOF
chown -R ansible:ansible ~ansible/.ssh/
chmod 700 ~ansible/.ssh/
chmod 600 ~ansible/.ssh/authorized_keys
cat <<_EOF > /etc/sudoers.d/ansible
Defaults:ansible !requiretty
ansible ALL=(ALL) NOPASSWD: ALL
_EOF
chmod 600 /etc/sudoers.d/ansible
```

* Create your inventory file. For example, inventories/fws.ini
```
[fws]
db.fws.fr
proxyin.fws.fr
```
This will create a single group **fws** with two hosts in it.

* Create your main playbook. This is the file describing what to deploy on which host. You can store it at in the root dir, for example, fws.yml :
```
- name: Deploy common profiles
  hosts: fws
  roles:
    - common
    - backup

- name: Deploy databases servers
  hosts: db.fws.fr
  roles:
    - mysql_server
    - postgresql_server

- name: Deploy reverse proxy
  hosts: proxyin.fws.fr
  roles:
    - nginx
    - letsencrypt
    - lemonldap_ng
```
It's pretty self-explanatory. First, roles **common** and **backup** will be deployed on every hosts in the fws group. Then, **mysql_server** and **postgresql_server** will be deployed on **db.fws.fr**. And roles **nginx**, **letsencrypt** and **lemonldap_ng** will be deployed on host **proxyin.fws.fr**

* Now, it's time to configure a few things. Configuration is done be assigning values to varibles, and can be done at several levels.
    * group_vars/all/vars.yml : variables here will be inherited by every hosts
```
ansible_become: True
trusted_ip:
  - 1.2.3.4
  - 192.168.47.0/24
zabbix_ip:
  - 10.11.12.13

system_admin_groups:
  - 'admins'
system_admin_users:
  - 'fws'
system_admin_email: servers@example.com

zabbix_agent_encryption: psk
zabbix_agent_servers: "{{ zabbix_ip }}"
zabbix_proxy_encryption: psk
zabbix_proxy_server: 'zabbix.example.com'
```
    * group_vars/fws/vars.yml : variables here will be inherited by hosts in the **fws** group
```
sshd_src_ip: "{{ trusted_ip }}"
postfix_relay_host: '[smtp.example.com]:587'
postfix_relay_user: smtp
postfix_relay_pass: "S3cretP@ssw0rd"

ssh_users:
  - name: ansible
    ssh_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCwnPxF7vmJA8Jr7I2q6BNRxQIcnlFaA3O58x8532qXIox8fUdYJo0KkjpEl6pBSWGlF4ObTB04/Nks5rhv9Ew+EHO5GvavzVp5L3u8T+PP+idlLlwIERL2R632TBWVbxqvhtc813ozpaMRI7nCabgiIp8rFf4hqYJIn/RMpRdPSQaHrPHQpFEW9uHPbFYZ9+dywY88WXY+VJI1rkIU3NlOAw3GKjEd6iqiOboDl8Ld4qqc+NpqDFPeidYbk5xjKv3l/Y804tdwqO1UYC+psr983rs1Kq91jI/5xSjSQFM51W3HCpZMTzSIt4Swy+m+eqUIrInxMmw72HF2CL+PePHgmusMUBYPdBfqHIxEHEbvPuO67hLAhqH1dUDBp+0oiRSM/J/DX7K+I+jNO43/UtcvnrBjNjzAiiJEG3WRAcBAUpccOu3JHcRN5CLRB26yfLXpFRzUNCnajmdZF7qc0G5gJuy8KpUZ49VTmZmJ0Uzx1rZLaytSjHpf4e5X6F8iTQ1QmORxvCdfdsqoeod7jK384NXq+UD24Y/tEgq/eT7pl3yLCpQo4qKd/aCEBqc2bnLggVRr+WX94ojMdK35qYbdXtLsN5y6L20yde8tGtWY+nmbJzLnqVJ4TKxXKMl7q9Sdj1t7BrqQQIK3H9kP7SZRhWNP6tvNKBgKFgc/k01ldw== ansible@fws.fr
  - name: dani
    allow_forwarding: True
    ssh_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCwnPxF7vmJA8Jr7I2q6BNRxQIcnlFaA3O58x8532qXIox8fUdYJo0KkjpEl6pBSWGlF4ObTB04/Nks5rhv9Ew+EHO5GvavzVp5L3u8T+PP+idlLlwIERL2R632TBWVbxqvhtc813ozpaMRI7nCabgiIp8rFf4hqYJIn/RMpRdPSQaHrPHQpFEW9uHPbFYZ9+
dywY88WXY+VJI1rkIU3NlOAw3GKjEd6iqiOboDl8Ld4qqc+NpqDFPeidYbk5xjKv3l/Y804tdwqO1UYC+psr983rs1Kq91jI/5xSjSQFM51W3HCpZMTzSIt4Swy+m+eqUIrInxMmw72HF2CL+PePHgmusMUBYPdBfqHIxEHEbvPuO67hLAhqH1dUDBp+0oiRSM/J/DX7K+I+jNO43/UtcvnrBjNjzAiiJEG3WRAcBAUpccOu3JHcRN5CLRB26yfLXpFRzUNCnajmdZF7qc0G5gJuy8KpUZ49VTmZmJ0Uzx1rZLaytSjHpf4e5X6F8iTQ1QmORxvCdfdsqoeod7jK384NXq+UD24Y/tEgq/eT7pl3yLCpQo4qKd/aCEBqc2bnLggVRr+WX94ojMdK35qYbdXtLsN5y6L20yde8tGtWY+nmbJzLnqVJ4TKxXKMl7q9Sdj1t7BrqQQIK3H9kP7SZRhWNP6tvNKBgKFgc/k01ldw== dani@fws.fr

# Default database server
mysql_server: db.fws.fr
mysql_admin_pass: "r00tP@ss"
pg_server: db.fws.fr
pg_admin_pass: "{{ mysql_admin_pass }}"

letsencrypt_challenge: dns
letsencrypt_dns_provider: gandi
letsencrypt_dns_provider_options: '--api-protocol=rest'
letsencrypt_dns_auth_token: "G7Bm9RckZdgI"
```
    * host_vars/proxyin.fws.fr/vars.yml : variables here will be inherited only by the host **proxyin.fws.fr**
```
nginx_auto_letsencrypt_cert: True

# Default vhost settings
nginx_default_vhost_extra:
  auth: llng
  csp: >-
    default-src 'self' 'unsafe-inline' blob:;
    style-src-elem 'self' 'unsafe-inline' data:;
    img-src 'self' data: blob: https://stats.fws.fr;
    script-src 'self' 'unsafe-inline' 'unsafe-eval' https://stats.fws.fr blob:;
    font-src 'self' data:
  proxy:
    cache: True
    backend: http://web1.fws.fr

nginx_vhosts:

  - name: mail-filter.example.com
    proxy:
      backend: https://10.64.2.10:8006
    allowed_methods: [GET,HEAD,POST,PUT,DELETE]
    src_ip: "{{ trusted_ip }}"
    auth: False

  - name: graphes.fws.fr
    proxy:
      backend: http://10.64.3.15:3000
    allowed_methods: [GET,HEAD,POST,PUT,DELETE]

```

## How to check available variables

Every role has default variables set in the defaults sub folder. You can have a look at it to see which variables are available and what default value they have.

## Contact

You can contact us at tech AT firewall-services DOT com if needed
