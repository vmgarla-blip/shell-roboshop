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
        echo -e  "$TIMESTAMP $R [ERROR]  $2 FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e " $TIMESTAMP $G [INFO] $2 SUCCESS $N" | tee -a $LOGS_FILE
    fi

}

dnf module disable redis -y
dnf module enable redis:7 -y
dnf install redis -y 
VALIDATE $? "Installing redis"

# sed -i s/127.0.0.1/0.0.0.0/g -e 'protected-mode/ c protected-mode no' /etc/redis/redis.conf

sed -i  -e 's/127.0.0.1/0.0.0.0/g'  -e '/^protected-mode/ c protected-mode no'  /etc/redis/redis.conf

VALIDATE $? "Allowing remote connection to redis"

systemctl enable --now redis &>> $LOGS_FILE
systemctl start redis &>> $LOGS_FILE

VALIDATE $? "Starting and Enabling redis"