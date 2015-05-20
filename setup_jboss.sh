#!/bin/bash
#
# setup_jboss.sh
#
# Download and extract JBoss, config it to listen on all IP address and set Jboss to be daemon and auto start with machine

DOWNLOAD_LINK="http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/jboss-as-7.1.1.Final.tar.gz";
TARGET_DIR="/opt";
JBOSS_HOME="$TARGET_DIR/Jboss"
# Check if the script is ran as root
if [ `id -u` -ne 0 ]; then
    # Not the root
    echo "Please make sure this script is ran as root!";
    exit 1;
fi

# Create JBOSS_HOME directory and cd there to prepare
mkdir -p $JBOSS_HOME;
cd $TARGET_DIR;

# Download and extract Jboss
wget $DOWNLOAD_LINK;
jboss_tar_file=${DOWNLOAD_LINK##*/};
echo "Extracting $jboss_tar_file";
tar xzvf $jboss_tar_file -C $JBOSS_HOME --strip=1
chown -R vagrant:vagrant $JBOSS_HOME;

# Modify standalone profile to listen on all IP addresses
sed -iE "s/<inet-.*127.*/<any-ipv4-address\/>/" "$JBOSS_HOME/standalone/configuration/standalone.xml"

# Advanced tasks, 
# Change http port for Jboss to 9090
new_port=9090;
sed -ie "s/\(.*http\" port=\"\)[0-9]*\(\"\/\)/\1$new_port\2/" "$JBOSS_HOME/standalone/configuration/standalone.xml"

# Change ajp port to 9091
new_port=9091;
sed -ie "s/\(.*ajp\" port=\"\)[0-9]*\(\"\/\)/\1$new_port\2/" "$JBOSS_HOME/standalone/configuration/standalone.xml"

# change context of sample.war app
cd /tmp/
wget --no-check-certificate https://tomcat.apache.org/tomcat-6.0-doc/appdev/sample/sample.war
jar xvf sample.war
rm sample.war
config_file="WEB-INF/jboss-web.xml";
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" 	> $config_file;
echo "<jboss-web>" 								>> $config_file;
echo "    <context-root>/changed-context</context-root>" 		>> $config_file;
echo "</jboss-web>" 							>> $config_file;
jar cvf new_sample.war *
cp new_sample.war $JBOSS_HOME/standalone/deployments/
cd $JBOSS_HOME

# disable welcome page
sed -ie "s/\(.*enable-welcome-root=\"\).*\(\".*\)/\1false\2/" "$JBOSS_HOME/standalone/configuration/standalone.xml"

# set access logging via Valve for default-host
sed -ie '/<virtual-server.*default-host.*/a <access-log>\n <directory path="." relative-to="jboss.server.log.dir"/>  \n</access-log>' "$JBOSS_HOME/standalone/configuration/standalone.xml"

# add AJP connector for default server
sed -ie '/.*connector name="http".*/a<connector name="ajp" protocol="AJP/1.3" scheme="http" socket-binding="ajp"/>' "$JBOSS_HOME/standalone/configuration/standalone.xml"

# End advanced tasks

# Make JBoss a Daemon and set it to automatically startic
ln -s $JBOSS_HOME/bin/init.d/jboss-as-standalone.sh /etc/init.d/jboss
chmod +x /etc/init.d/jboss
# chkconfig --level 356 jboss on

# Configuration dir for JBOSS
mkdir /etc/jboss-as
echo -e "JBOSS_HOME=$JBOSS_HOME" > /etc/jboss-as/jboss-as.conf
echo "JBOSS_CONSOLE_LOG=/var/log/jboss-console.log" >> /etc/jboss-as/jboss-as.conf
echo "JBOSS_USER=root" >> /etc/jboss-as/jboss-as.conf

# Download a simple Helloworld to deply to Jboss
cd "$JBOSS_HOME/standalone/deployments/";
#wget --no-check-certificate https://github.com/spagop/quickstart/raw/master/management-api-examples/mgmt-deploy-application/application/jboss-as-helloworld.war
wget --no-check-certificate https://tomcat.apache.org/tomcat-6.0-doc/appdev/sample/sample.war
chown vagrant:vagrant *

# 2nd GROUP OF ADVANCED TASKS
key_store_pass="a123456"
key_store_loc="$JBOSS_HOME"
key_store_name="xkck.keystore"
/opt/jdk1.7.0_76/bin/keytool -genkey -alias XKCD -keyalg RSA -keystore $key_store_loc/$key_store_name -validity 10950 -storepass $key_store_pass -keypass $key_store_pass -dname "CN=A,OU=B,O=C.com,L=D,S=E,C=F"

# add https socket binding for default-host
# sed -ie "s/\(.*socket-binding=\"http\"[^/]*\)/\1 redirect-port=\"443\"/" "$JBOSS_HOME/standalone/configuration/standalone.xml"
# sed -ie '/redirect-port.*/a <connection name="https" scheme="https" protocol="HTTP/1.1" socket-binding="https" enable-lookups="false" secure="true">\n<ssl name="foo-ssl" password="KEYPASSWORD" protocol="TLSv1" key-alias="XKCD" certificate-key-file="/opt/Jboss/KEYNAME" />\n</connector>' "$JBOSS_HOME/standalone/configuration/standalone.xml"
# sed -i "s/KEYPASSWORD/$key_store_pass/" "$JBOSS_HOME/standalone/configuration/standalone.xml"
# sed -i "s/KEYNAME/$key_store_name/" "$JBOSS_HOME/standalone/configuration/standalone.xml"

# Start JBoss
service jboss start