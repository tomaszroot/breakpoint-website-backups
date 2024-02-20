 
#  Backup breakpoint for a web page 

## Overview
A script to create and restore copies of sites while they are being built. The script is designed to make a backup copy of the site at any given time. If further site building fails, you can restore a working copy of the site.

## How to use
To use this tool, place the script in the directory where the backups will be stored. Change permissions to `chmod +x b.sh`.

## Requirements
This script has been tested only on Linux. Additionally, it needs the following tools to be present on your system:

- `openssh` (tested with 9.6p1-1)
- `sshpass` (tested with 1.10-1)

## Configuration
Complete the following variables:

- `ssh_pass` SSH password
- `ssh_port` SSH port
- `ssh_host` SSH username and hostname, example: username@hostname.com
- `ssh_path` path to website directory
- `mysql_host` database hostname
- `mysql_user` database username
- `mysql_base` database name
- `mysql_pass` database password

## Usage
- `./b.sh b` make a backup
- `./b.sh +b` or `./b.sh x` backup a large website (increases disk operations - decreases transfer)
- `./b.sh r` restore backup
- `./b.sh backup` see command to manually save the backup
- `./b.sh restore` see manual backup restore command