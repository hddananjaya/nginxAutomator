#!/bin/bash
function checkRequiredUtils() {
    utilSetToInstall=()
    utilSet=("nginx" "apache2" "php-fpm7.2")
    for util in ${utilSet[*]}; do
        type $util >>installInfo.log 2>&1
        exitCode=$?
        if [ $exitCode -ne 0 ]; then
            echo "[!] Require '${util}' but can't find"
            utilSetToInstall+=("$util")
        else 
            if [ "$util" = "nginx" ]; then
                nginx -v 2>&1 |grep 1.14 >>installInfo.log 2>&1
                exitCode=$?
                if [ $exitCode -ne 0 ]; then
                    echo "[!] Nginx version mismatching"
                    utilSetToInstall+=("nginx")
                fi
            fi
            if [ "$util" = "apache2" ]; then
                apache2 -v |grep 2.4 >>installInfo.log 2>&1
                exitCode=$?
                if [ $exitCode -ne 0 ]; then
                    echo "[!] Apache version mismatching"
                    utilSetToInstall+=("apache2")
                fi
            fi
        fi
    done
}

function installRequiredUtils() {
    for util in ${utilSetToInstall[*]}; do
        if [ "$util" = "nginx" ]; then
            echo "[*] Installing nginx 1.14.*..."
            apt-get install nginx=1.14.*
            exitCode=$?
            if [ $exitCode -ne 0 ]; then
                echo "[!] There was an issue when installing ${util}"
                exit 1
            fi
        elif [ "$util" = "apache2" ]; then
            echo "[*] Installing apache2 2.4.*..."
            apt-get install apache2=2.4.*
            exitCode=$?
            if [ $exitCode -ne 0 ]; then
                echo "[!] There was an issue when installing ${util}"
                exit 1
            fi
        elif [ "$util" = "php-fpm7.2" ]; then
            echo "[*] Installing php7.2 and php7.2-fpm..."
            apt-get install php7.2 php7.2-fpm
            exitCode=$?
            if [ $exitCode -ne 0 ]; then
                echo "[!] There was an issue when installing ${util}"
                exit 1
            fi
        fi
    done
}

function checkRequiredPorts() {
    # stop if nginx or apache is already running
    systemctl stop nginx >>installInfo.log 2>&1
    systemctl stop apache2 >>installInfo.log 2>&1
    portSet=("80" "8001")
    for port in ${portSet[*]}; do
        netstat -tulpn | grep "$port " >>installInfo.log 2>&1
        exitCode=$?
        if [ $exitCode -eq 0 ]; then
            echo "[!] Port ${port} is already used"
            echo "[?] Do you want to kill process on port $port? [y/n]"
            read response
            if [ "$response" = "y" ]; then
                echo "[!] Killing process on port $port"
                kill -9 $(sudo lsof -t -i:$port)
            else
                echo "[!] Required port $port is not available. Exiting.."
                exit 1
            fi
        fi
    done
    echo "[*] Found required ports"
}

function startNginxAndApacheServices() {
    serviceSet=("nginx" "apache2")
    for service in ${serviceSet[*]}; do
        systemctl start $service >>installInfo.log 2>&1
        exitCode=$?
        if [ $exitCode -ne 0 ]; then
            echo "[!] There is an issue when starting ${service}"
            exit 1
        fi
    done
    ls /run/php/php7.2-fpm.sock &> installInfo.log
    exitCode=$?
    if [ $exitCode -ne 0 ]; then
        echo "[!] Can't find /run/php/php7.2-fpm.sock"
        exit 1
    fi
    echo "[*] Nginx and Apache services started properly"
}

function copyFoldersFromPackage() {
    # copy from package
    cp -rf ./nginx/ssl ./nginx/assignment2 ./nginx/nginx.conf /etc/nginx/
    cp ./nginx/sites-available/* /etc/nginx/sites-available
    ln -s /etc/nginx/sites-available/*.nginx.test.conf /etc/nginx/sites-enabled >>installInfo.log 2>&1
    cp -r ./www/* /var/www/
    cp -f ./apache/ports.conf /etc/apache2/
    echo "[*] Successfully copied files"

    # changing /etc/hosts and /etc/apache2/ports.conf
    cat /etc/hosts | grep site1.nginx.test >>installInfo.log 2>&1
    exitCode=$?
    if [ $exitCode -eq 0 ]; then
        echo "[-] /etc/hosts is already configured"
    else 
        echo -e "\n127.0.0.1	site1.nginx.test" >>/etc/hosts
        echo -e "127.0.0.1	site2.nginx.test" >>/etc/hosts
        echo -e "127.0.0.1	assignment2.nginx.test" >>/etc/hosts
        echo "[*] /etc/hosts file changed"
    fi

    cat /etc/apache2/ports.conf | grep 8001 >>installInfo.log 2>&1
    exitCode=$?
    if [ $exitCode -eq 0 ]; then
        echo "[-] Port 8001 is already declared in /etc/apache2/ports.conf"
    else 
        echo -e "\nListen 8001" >>/etc/apache2/ports.conf
        echo "[*] Port 8001 added to /etc/apache2/ports.conf"
    fi
}

function backupCurretData(){
    # backup process
    timestamp=$(date +%d-%m-%Y_%H-%M-%S)
    mkdir ./backups >>installInfo.log 2>&1
    mkdir ./backups/$timestamp >>installInfo.log 2>&1
    cp -rf /etc/nginx ./backups/$timestamp
    cp -rf /var/www ./backups/$timestamp
    cp -rf /etc/apache2 ./backups/$timestamp
}

function main() {
    touch installInfo.log
    checkRequiredPorts
    checkRequiredUtils
    installRequiredUtils
    backupCurretData
    copyFoldersFromPackage
    startNginxAndApacheServices
}

main
