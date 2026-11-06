#!/bin/bash
set -e
sudo apt update -y
cd /home/ubuntu
mkdir -p Downloads
cd Downloads
currDir=$(pwd)
sudo apt install git curl -y
git clone "https://github.com/OmkarMensi/Recruitment"
frontend="$currDir/Recruitment/frontend"
backend="$currDir/Recruitment/backend"
ENV_PATH="$currDir/Recruitment/.env"
set -a
source "$ENV_PATH"
set +a


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
if [[ -z "$(command -v java)" ]]; then
	echo -e "proceeding to install openjdk..\n"
	sudo apt install openjdk-17-jdk -y
	java --version
	javac --version
	sudo update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java
	sudo update-alternatives --set javac /usr/lib/jvm/java-17-openjdk-amd64/bin/javac
fi
if [[ -z "$(command -v mysql)" ]]; then
	echo -e "proceeding to install mysql...\n"
	sudo apt install mysql-server -y

fi

sudo systemctl enable mysql
sudo systemctl start mysql
mysql --version


mvn clean install -DskipTests 2>error.log

sudo mysql<<EOF
CREATE DATABASE IF NOT EXISTS $dbname;
CREATE USER IF NOT EXISTS '$dbuser'@'localhost' IDENTIFIED BY '$dbpassword';
GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';
FLUSH PRIVILEGES;
exit
EOF

cd target
java -jar *.jar & 
