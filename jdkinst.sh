#!/bin/bash

TYPE="jdk"
VERSION="8"
EXT="tar.gz"
OS="x64"

OS_TYPE=`uname`
OS_NAME="linux"

if [ ${OS_TYPE} == 'Linux' ]; then
	OS_NAME="linux"
fi

if [ ${OS_TYPE} == 'Darwin' ]; then
	OS_NAME="macosx"
	EXT="dmg"
fi


MACHINE_TYPE=`uname -m`
if [ ${MACHINE_TYPE} == 'x86_64' ]; then
	OS="x64"
else
	OS="i586"
fi

if [[ -n "$1" ]]; then
  if [[ "$1" == "7" ]]; then
	VERSION="7"
  fi
fi

URL="http://www.oracle.com"
URL1="${URL}/technetwork/java/javase/downloads/index.html"
URL2=$(curl -s $URL1 | egrep -o "\/technetwork\/java/\javase\/downloads\/${TYPE}${VERSION}-downloads-.*\.html" | head -1)

if [[ -z "$URL2" ]]; then
  echo "Could not download - $URL1"
  exit 1
fi


URL3="$(echo ${URL}${URL2}|awk -F\" {'print $1'})"
URL4=$(curl -s "$URL3" | egrep -o "http\:\/\/download.oracle\.com\/otn-pub\/java\/jdk\/[7-8]u[0-9]+\-(.*)+\/${TYPE}-[7-8]u[0-9]+(.*)${OS_NAME}-${OS}.${EXT}")

if [[ -z "$URL4" ]]; then
  echo "Could not get ${TYPE} download url - $URL4"
  exit 1
fi

URL5=$(echo $URL4|cut -d " " -f 1)

JAVA_INSTALL=$(echo $URL5|cut -d "/" -f 8)
if [[ -z "$JAVA_INSTALL" ]]; then
  echo "Could not be JAVA_INSTALL - $JAVA_INSTALL"
  exit 1
fi

echo $JAVA_INSTALL

function pw1()
{
	sudo -v -p "Password for Installation."
}
function pw2()
{
	sudo -v -p "Retry password for Installation."
}

pw1

if [ ! -d "/usr/local" ]; then
	sudo mkdir "/usr/local" 
fi	
if [ ! -d "/usr/local/src" ]; then
	sudo mkdir "/usr/local/src" 
fi	

cd /usr/local/src

sudo rm -f "$JAVA_INSTALL"

if [ ${OS_TYPE} == 'Darwin' ]; then
sudo curl --cookie "oraclelicense=accept-securebackup-cookie" --location-trusted -O $URL5
else
sudo wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" $URL5
fi

pw2

if [ ${OS_TYPE} == 'Darwin' ]; then

	VS0=$(echo $JAVA_INSTALL|cut -d "-" -f 1)
	VS1=$(echo $JAVA_INSTALL|cut -d "-" -f 2)
	VS2="${VS1/u/ Update }"
	VS3="/Volumes/JDK ${VS2}"
	VS4="${VS3}/JDK ${VS2}.pkg"
	
	hdiutil unmount "${VS3}"
	hdiutil mount "${JAVA_INSTALL}"
	open -W "${VS4}"
	hdiutil unmount "${VS3}"
	
	sudo rm -f "$JAVA_INSTALL"
fi

if [ ${OS_TYPE} == 'Linux' ]; then
	
	tar xvzf $JAVA_INSTALL
	rm -f $JAVA_INSTALL

	VS0=$(echo $JAVA_INSTALL|cut -d "-" -f 1)
	VS1=$(echo $JAVA_INSTALL|cut -d "-" -f 2)
	VS2="${VS1/u/.0_}"

	JAVA_DIR="${VS0}1.${VS2}"
	JAVA_PATH="/usr/local/${JAVA_DIR}"

	sudo chown -R root:root ${JAVA_DIR}

	sudo rm -rf "${JAVA_PATH}"
	sudo mv ${JAVA_DIR} /usr/local/.

	sudo rm -f /usr/bin/java
	sudo ln -s "${JAVA_PATH}/bin/java" /usr/bin/.

	sudo rm -f /usr/bin/javac
	sudo ln -s "${JAVA_PATH}/bin/javac" /usr/bin/.

	sudo rm -f /usr/bin/jar
	sudo ln -s "${JAVA_PATH}/bin/jar" /usr/bin/.

fi

pw2

java -version
javac -version
