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
curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading cart application"
cd /app 
VALIDATE $? "Chaning to app directory"
rm -rf /app/*
unzip /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "Unzip cart"
npm install &>>$LOG_FILE
VALIDATE $? "Install dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service &>>$LOG_FILE
VALIDATE $? "Copy system services"

systemctl daemon-reload 
VALIDATE $? "Daemon reload"

systemctl enable cart &>>$LOG_FILE
VALIDATE $? "Enable cart"
systemctl start cart &>>$LOG_FILE
VALIDATE $? "Start cart"
cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
VALIDATE $? "Copy mongo repo"

systemctl restart cart &>>$LOG_FILE
VALIDATE $? "Restart cart"