#!/bin/bash
set -e

sudo apt update -y
sudo apt install git curl unzip -y

curl -fsSL https://awscli.amazonaws.com/v2/install.sh | sudo bash -s -- --system

aws --version
cd /home/ubuntu/
mkdir -p Downloads
cd Downloads
git clone https://github.com/OmkarMensi/Recruitment
cd Recruitment
frontend="/home/ubuntu/Downloads/Recruitment/frontend"
backend="/home/ubuntu/Downloads/Recruitment/backend"
dbname=$(aws ssm get-parameter \
	--name "/recruitment/MYSQL_DATABASE" \
	--query "Parameter.Value" \
	--output text)

dbuser=$(aws ssm get-parameter \
	--name "/recruitment/MYSQL_USER" \
	--query "Parameter.Value" \
	--output text)

dbuserpass=$(aws ssm get-parameter \
	    --name "/recruitment/MYSQL_PASSWORD" \
	    --with-decryption \
	   --query "Parameter.Value" \
	   --output text)



sudo apt install openjdk-17-jdk -y

if [[ -z "$(command -v mvn)" ]]; then
	echo -e "maven doesnt exist,proceeding to install maven....\n"
	sudo apt install maven -y 
fi

sudo update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java 
sudo update-alternatives --set javac /usr/lib/jvm/java-17-openjdk-amd64/bin/javac

if [[ -z "$(command -v node)" ]]; then
	echo -e "proceeding to install nodejs...\t\n"
	sudo apt install nodejs npm -y
fi

if [[ -z "$(command -v mysql)" ]]; then
	echo -e "proceeding to install mysql...\t\n"
	sudo apt install mysql-server -y
fi

sudo systemctl enable mysql
sudo systemctl start mysql

cd "$frontend"
npm install
npm run build
nohup npm start &

cd "$backend"
mvn clean install -DskipTests
cd target
sudo mysql<<EOF
 CREATE DATABASE IF NOT EXISTS $dbname;
 CREATE USER IF NOT EXISTS '$dbuser'@'localhost' IDENTIFIED BY '$dbuserpass';
 GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';
 FLUSH PRIVILEGES;
EOF

export dbname
export dbuser
export dbuserpass

export SPRING_DATASOURCE_USERNAME="$dbuser"
export SPRING_DATASOURCE_PASSWORD="$dbuserpass"
nohup java -jar recruitment-1.0.0.jar &
