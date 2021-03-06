#!/usr/bin/env bash
################################################################################################################
# Ref: http://docs.opendaylight.org/en/stable-oxygen/developer-guide/developing-apps-on-the-opendaylight-controller.html
################################################################################################################

set -xe

# Generic configuration
export WORKSPACE=$PWD
export http_proxy=$1
export https_proxy=$1
export HOST_FORWARDED_PORT=$2

# Configuration for Gerrit access
export GIT_ID=${3}
export GIT_USERNAME=${4}
export GERRIT_KEY_FILE_NAME=${5}

# Host Configuration
HOST_IFACE=$(ip route | grep "^default" | head -1 | awk '{ print $5 }')
LOCAL_IP=$(ip addr | awk "/inet/ && /${HOST_IFACE}/{sub(/\/.*$/,\"\",\$2); print \$2}")
cat << EOF | sudo tee -a /etc/hosts
${LOCAL_IP} $(hostname)
EOF

if [ ! -z "$http_proxy" ]
then
# Proxy related settings - apt-get
cat << EOF | sudo tee -a /etc/apt/apt.conf
Acquire::http::Proxy "$http_proxy";
Acquire::https::Proxy "$https_proxy";
EOF
fi

################################################################################################################
# Environment setup
################################################################################################################

# Oracle Java 8
sudo apt-add-repository ppa:webupd8team/java
sudo apt-get update -y
# Accept oracle license terms
sudo echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
sudo apt-get install -y oracle-java8-installer

# Add to ~/.bashrc for persistence through a reboot
echo "export JAVA_HOME=/usr/lib/jvm/java-8-oracle" >> ~/.profile && source ~/.profile

echo "Java is on version `java -version`"

sudo apt-get install -y unzip git wget

git config --global user.email $GIT_ID
git config --global user.name $GIT_USERNAME
git config --global user.editor "vim"

# Download shaker-controller docker image
mkdir $WORKSPACE/work; cd $WORKSPACE/work

# Switch to working directory
cd $WORKSPACE/work

# Maven
#export MAVEN_REPO_URL="http://mirror.its.dal.ca/apache/maven/maven-3/3.3.9/binaries"
#export MAVEN_BINARY_TAR="apache-maven-3.3.9-bin.tar.gz"
#export MAVEN_BINARY="apache-maven-3.3.9"
export MAVEN_REPO_URL="http://mirror.its.dal.ca/apache/maven/maven-3/3.5.3/binaries"
export MAVEN_BINARY_TAR="apache-maven-3.5.3-bin.tar.gz"
export MAVEN_BINARY="apache-maven-3.5.3"
sudo apt-get purge -y maven
wget -q $MAVEN_REPO_URL/$MAVEN_BINARY_TAR
tar -zxf $MAVEN_BINARY_TAR
sudo cp -R $MAVEN_BINARY /usr/local
sudo ln -s /usr/local/$MAVEN_BINARY/bin/mvn /usr/bin/mvn
echo 'Unseting M2_HOME...'
unset M2_HOME
echo 'Exporting new M2_HOME...'
echo "export M2_HOME=/usr/local/$MAVEN_BINARY" >> ~/.profile
echo "export MAVEN_OPTS='-Xmx1048m -XX:MaxPermSize=512m'" >> ~/.profile
echo "export PATH=/usr/local/$MAVEN_BINARY/bin:$PATH" >> ~/.profile

source ~/.profile

echo "Maven is on version `mvn --version`"

# Setting OpenDaylight repositories for both users (vagrant/root)
echo "ODL Maven settings.xml..."
mkdir -p /home/vagrant/.m2/
wget -q -O - https://raw.githubusercontent.com/opendaylight/odlparent/master/settings.xml > /home/vagrant/.m2/settings.xml
sudo -s mkdir -p /root/.m2/
wget -q -O - https://raw.githubusercontent.com/opendaylight/odlparent/master/settings.xml | sudo tee -a /root/.m2/settings.xml

echo "Cloning OpenDaylight repositories..."
git clone https://github.com/opendaylight/odlparent.git
git clone https://github.com/opendaylight/yangtools.git -b stable/nitrogen
git clone https://github.com/opendaylight/controller.git -b stable/oxygen

cd odlparent
#git checkout -b boron remotes/origin/stable/boron
echo 'Compiling odlparent...'
mvn clean install -DskipTests -q
cd ..
cd yangtools
#git checkout -b boron remotes/origin/stable/boron
echo 'Compiling yangtools...'
mvn clean install -DskipTests -q
cd ..
cd controller
#git checkout -b boron remotes/origin/stable/boron
echo 'Compiling controller...'
mvn clean install -DskipTests -q
cd ..

echo "**** VM setup successfully! *** "
echo "To create your ODL application you should execute the following command and set requested properties..."

echo "mvn archetype:generate \
-DarchetypeGroupId=org.opendaylight.controller \
-DarchetypeArtifactId=opendaylight-startup-archetype \
-DarchetypeRepository=https://nexus.opendaylight.org/content/repositories/opendaylight.snapshot/ -DarchetypeCatalog=remote -DarchetypeVersion=1.6.0-SNAPSHOT"

echo "Follow link: http://docs.opendaylight.org/en/stable-oxygen/developer-guide/developing-apps-on-the-opendaylight-controller.html"

