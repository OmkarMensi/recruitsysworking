#!/bin/bash
set -e

cd ~/Downloads
if [[ ! -d Recruitment ]]; then
git clone https://github.com/OmkarMensi/Recruitment
fi
cd Recruitment
frontend="/home/omkar/Downloads/Recruitment/frontend"
backend="/home/omkar/Downloads/Recruitment/backend"
dbname="git_recruitment"
dbuser="springuser"

dbuserpass="spring123"



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

nohup java -jar recruitment-1.0.0.jar &
