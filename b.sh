#!/bin/bash

# How it works
# A script to create and restore copies of sites while they are being built.
# The script is designed to make a backup copy of the site at any given time.
# If further site building fails, you can restore a working copy of the site.
#
# Usage
# Make a copy: ./b.sh b
# Make a copy for large pages - increases disk operations - decreases transfer ./b.sh x or ./b.sh b+
# Restore a page from a copy: ./b.sh r
# See command to manually save the backup: ./b.sh backup
# See manual backup restore command: ./b.sh restore

# variables
ssh_pass=''
ssh_port=""
ssh_host=""
ssh_path=""
mysql_host=""
mysql_user=""
mysql_base=""
mysql_pass=''


# constants
mysql_file="backup_$(date +%s)$(date +%s | base64).sql"
date="$(date +%F)"

# selection of: SSH password and port ; MySQL host.
if [ -z $ssh_pass ]
then
    ssh_pass="no_password"
fi

if [ -z $ssh_port ]
then
    ssh_port="22"
fi

if [ -z $mysql_host ]
then
    mysql_host="localhost"
fi

# operation
operation=$1

# what should I do?
case $operation in
    "b") # back up
    
        # creation of a directory
        i=0
        while [ -d "${date}_$i" ]; do
            ((i++))
        done
        last="${date}_$i"
        mkdir $last

        echo "Deleting the base"
        sshpass -p $ssh_pass ssh -p $ssh_port $ssh_host "rm -f $ssh_path/backup_*.sql"
        
        echo "Base dump"
        sshpass -p $ssh_pass ssh -p $ssh_port $ssh_host "cd $ssh_path && mysqldump --no-tablespaces -h$mysql_host -u$mysql_user -p'$mysql_pass' $mysql_base > $mysql_file"
        
        echo "Backup in progress..."
        sshpass -p $ssh_pass rsync -azz --info=progress2 -e "ssh -p $ssh_port" $ssh_host:$ssh_path/ $last
        
        echo "Deleting the base"
        sshpass -p $ssh_pass ssh -p $ssh_port $ssh_host "rm -f $ssh_path/backup_*.sql"
        
        base=$last/backup_*.sql
        
        if [ -s $base ]
        then
            echo "|" $last "|" "OK"
        fi 
    ;;
    "b+"|"x") # backup for large sites
        previous="$(ls -vd */ | tail -1)"

        # creation of a directory
        i=0
        while [ -d "${date}_$i" ]; do
            ((i++))
        done
        last="${date}_$i"
        mkdir $last

        echo "Copying files from a previous directory"

        rsync -azz $previous/ $last

        echo "Deleting the base"
        sshpass -p $ssh_pass ssh -p $ssh_port $ssh_host "rm -f $ssh_path/backup_*.sql"
        
        echo "Base dump"
        sshpass -p $ssh_pass ssh -p $ssh_port $ssh_host "cd $ssh_path && mysqldump --no-tablespaces -h$mysql_host -u$mysql_user -p'$mysql_pass' $mysql_base > $mysql_file"
        
        echo "Backup in progress..."
        sshpass -p $ssh_pass rsync -azz --info=progress2 --delete -e "ssh -p $ssh_port" $ssh_host:$ssh_path/ $last
        
        echo "Deleting the base"
        sshpass -p $ssh_pass ssh -p $ssh_port $ssh_host "rm -f $ssh_path/backup_*.sql"
        
        base=$last/backup_*.sql
        
        if [ -s $base ]
        then
            echo "|" $last "|" "OK"
        fi 
    ;;
    "r") # restore backup
        read -p "Confirm (y): " -n 1 -r
        if [[ $REPLY =~ ^[y]$ ]]
        then
        echo ""
                        
        last="$(ls -vd */ | tail -1)"
        
        echo "Restoring a backup in progress..." $last
        sshpass -p $ssh_pass rsync -azz --info=progress2 --delete $last/ -e "ssh -p $ssh_port" $ssh_host:$ssh_path/

        echo "Base recovery"
        sshpass -p $ssh_pass ssh -p $ssh_port $ssh_host "cd $ssh_path && mysql -h$mysql_host -u$mysql_user -p'$mysql_pass' $mysql_base < backup_*.sql"

        echo "Deleting the base"
        sshpass -p $ssh_pass ssh -p $ssh_port $ssh_host "rm -f $ssh_path/backup_*.sql"
        fi
    ;;
    "backup") # show me command to make a copy
        echo "Manual command <<"
        echo "sshpass -p '$ssh_pass' ssh -p $ssh_port $ssh_host 'rm -f $ssh_path/backup_*.sql' ; sshpass -p '$ssh_pass' ssh -p $ssh_port $ssh_host 'cd $ssh_path && mysqldump --no-tablespaces -h$mysql_host -u$mysql_user -p\"$mysql_pass\" $mysql_base > backup_\$(date +%s)\$(date +%s | base64).sql' && sshpass -p '$ssh_pass' rsync -azz --delete --info=progress2 -e 'ssh -p $ssh_port' $ssh_host:$ssh_path/ . ; sshpass -p '$ssh_pass' ssh -p $ssh_port $ssh_host 'rm -f $ssh_path/backup_*.sql'"
    ;;
    "restore") # show me the restore copy command
        echo "Manual command ←"
        echo "sshpass -p '$ssh_pass' rsync -azz --delete --info=progress2 . -e 'ssh -p $ssh_port' $ssh_host:$ssh_path/ && sshpass -p '$ssh_pass' ssh -p $ssh_port $ssh_host 'cd $ssh_path && mysql -h$mysql_host -u$mysql_user -p\"$mysql_pass\" $mysql_base < backup_*.sql' ; sshpass -p '$ssh_pass' ssh -p $ssh_port $ssh_host 'rm -f $ssh_path/backup_*.sql'"
esac