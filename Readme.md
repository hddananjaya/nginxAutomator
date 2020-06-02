## Usage

Install and configure Assignment01. Installs a nginx server as a reverse proxy for 
a apache server. Modifies `/etc/hosts` to make available following virtual hosts.
- http://site1.nginx.test/
- http://site2.nginx.test/
- https://assignment2.nginx.test/

## Installation
Follow bellow instructions to install. You can find backups of your current `/etc/nginx` and `/var/www/` folders in `./backups` after running the installer.

```bash
cd ./package
chmod u+x ./install.sh
sudo ./install.sh
```

## Version
- Nginx 1.14.*
- Apache 2.4.*
- php7.2, php7.2-fpm

