#!/bin/bash
LOGS_FOLDER="/var/logs/roboshop"
sudo mkdir -p $LOGS_FOLDER
sudo chown ec2-user:ec2-user $LOGS_FOLDER
sudo chmod 755 $LOGS_FOLDER
LOGS_FILE=$LOGS_FOLDER/$0.log

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
if [ $USERID -ne 0 ]; then
    echo -e "  $TIMESTAMP $R [ERROR]  Please run the script as root user $N"
    exit 1
fi

VALIDATE () {

    if [ $1 -ne 0  ]; then
        echo -e  "$TIMESTAMP $R [ERROR]  $1 installation failed $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e " $TIMESTAMP $G [INFO] $1 installed successfully $N" | tee -a $LOGS_FILE
    fi

}

cp mongodb.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding mongodb repo"