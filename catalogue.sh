#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.jashvika.online
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-roboshop/

mkdir -p $LOGS_FOLDER

echo "Script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privelege"
    exit 1 # failure is other than 0
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then 
        echo -e "$2 ...$R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else 
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi    
}

#####NodeJS####
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disable NodeJS"
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling NodeJS"
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Install NodeJS"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating system user"
else
    echo -e "User already exist ... $Y SKIPPING $N"   
fi

mkdir -p /app 
VALIDATE $? "Creating App directory"
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading catalogue application"
cd /app 
VALIDATE $? "Chaning to app directory"
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unzip Catalogue"
npm install &>>$LOG_FILE
VALIDATE $? "Install dependencies"
cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE
VALIDATE $? "Copy system services"
systemctl daemon-reload
VALIDATE $? "Daemon reload"
systemctl enable catalogue 
VALIDATE $? "Enable catalogue"
systemctl start catalogue &>>$LOG_FILE
VALIDATE $? "Start catalogue"
cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copy mongo repo"
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Install mongoDB client"
mongosh --host $MONGODB_HOST </app/db/master-data.js
VALIDATE $? "Load Catalogue product"
systemctl restart catalogue
VALIDATE $? "Restart catalogue"