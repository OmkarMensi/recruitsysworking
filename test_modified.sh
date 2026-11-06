#!/bin/bash
set -e

sudo apt update -y
sudo apt install git curl unzip -y

curl -fsSL https://awscli.amazonaws.com/v2/install.sh | sudo bash -s -- --system

aws --version
cd /home/ubuntu
mkdir -p Downloads
cd Downloads
currDir=$(pwd)
git clone "https://github.com/OmkarMensi/Recruitment"
frontend="$currDir/Recruitment/frontend"
backend="$currDir/Recruitment/backend"

MYSQL_DATABASE=$(aws ssm get-parameter \
    --name "/recruitment/MYSQL_DATABASE" \
    --query "Parameter.Value" \
    --output text)

MYSQL_USER=$(aws ssm get-parameter \
    --name "/recruitment/MYSQL_USER" \
    --query "Parameter.Value" \
    --output text)

MYSQL_PASSWORD=$(aws ssm get-parameter \
    --name "/recruitment/MYSQL_PASSWORD" \
    --with-decryption \
    --query "Parameter.Value" \
    --output text)

MYSQL_ROOT_PASSWORD=$(aws ssm get-parameter \
    --name "/recruitment/MYSQL_ROOT_PASSWORD" \
    --with-decryption \
    --query "Parameter.Value" \
    --output text)

MAIL_APP=$(aws ssm get-parameter \
    --name "/recruitment/MAIL_APP" \
    --with-decryption \
    --query "Parameter.Value" \
    --output text)

dbname="$MYSQL_DATABASE"
dbuser="$MYSQL_USER"
dbpassword="$MYSQL_PASSWORD"


if [[ -z "$(command -v node)" ]]; then
    echo "Node.js doesn't exist, proceeding to install Node.js..."
    sudo apt install nodejs npm -y
fi

node --version
npm --version

cd "$frontend"
npm install #installs dependencies
npm run build #creates a build
nohup npm start &
cd ..
cd "$backend"
if [[ -z "$(command -v mvn)" ]]; then
	echo -e "proceeding to install maven..\n"
	sudo apt install maven -y
	mvn --version
fi

echo -e "proceeding to install openjdk..\n"
sudo apt install openjdk-17-jdk -y
java --version
javac --version
sudo update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java
sudo update-alternatives --set javac /usr/lib/jvm/java-17-openjdk-amd64/bin/javac

if [[ -z "$(command -v mysql)" ]]; then
	echo -e "proceeding to install mysql...\n"
	sudo apt install mysql-server -y

fi

sudo systemctl enable mysql
sudo systemctl start mysql
mysql --version


mvn clean install -DskipTests 

sudo mysql<<EOF
CREATE DATABASE IF NOT EXISTS $dbname;
CREATE USER IF NOT EXISTS '$dbuser'@'localhost' IDENTIFIED BY '$dbpassword';
GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';
FLUSH PRIVILEGES;
exit
EOF

export MYSQL_DATABASE
export MYSQL_USER
export MYSQL_PASSWORD
export MAIL_APP

export SPRING_DATASOURCE_USERNAME="$MYSQL_USER"
export SPRING_DATASOURCE_PASSWORD="$MYSQL_PASSWORD"

cd target
java -jar *.jar & 
