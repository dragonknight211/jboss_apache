#!/bin/bash
# centos_lamp.sh
#
# install LAMP packages on CentOS 6.5

# Check if the script is ran as root
if [ `id -u` -ne 0 ]; then
    # Not the root
    echo "Please make sure this script is ran as root!";
    exit 1;
fi

# install httpd as a service
installed_status=`ls /etc/init.d/ | grep httpd | wc -l`
if [ $installed_status == 0 ]; then
    # httpd is not installed, install it by yum now
    yum -y install httpd
fi

# Make virtualhost as frontend for jboss
site_name="tan.internavi.tk"; # Name of the selected site, also the URL to access it
HOME_DIR="/opt/$site_name";   # Home directory of this virtual host
VIRTUAL_HOST_CONFIG_DIR="/etc/httpd/conf.d";

# Create the home directory for the site if need to 
if [ ! -d $HOME_DIR ]; then
    mkdir -p $HOME_DIR;
fi

# Get current IP address of server
SERVER_IP=`ifconfig eth1 | awk '/inet addr/{print substr($2,6)}'`;

echo " Index file of $site_name running on server $SERVER_IP, this file is in $HOME_DIR, created on `date`" > $HOME_DIR/index.html

# Set this site into hosts file if not already
host_file_status=`grep $site_name /etc/hosts | wc -l`;
if [ $host_file_status == 0 ]; then
    echo -n "127.0.0.1\t$site_name" >> /etc/hosts
fi

# Make the virtualhost file to apache
# Config this virtualhost to use backend server by mod_proxy
virtual_host_file="$VIRTUAL_HOST_CONFIG_DIR/$site_name.conf";
touch $virtual_host_file;
echo "<Proxy balancer://mycluster>"		> $virtual_host_file;
echo "Order deny,allow"					>> $virtual_host_file;
echo "Allow from all"					>> $virtual_host_file;
echo "BalancerMember ajp://192.168.33.21:9091/changed-context"		>> $virtual_host_file;
echo "</Proxy>"							>> $virtual_host_file;

echo "<VirtualHost *:8080>"               >> $virtual_host_file;
echo -e "\tServerName\t$site_name"      >> $virtual_host_file;
echo -e "\tDocumentRoot\t$HOME_DIR/"    >> $virtual_host_file;
echo -e "\t<Directory \"$HOME_DIR/\">"  >> $virtual_host_file;
echo -e "\t\tAllowOverride All"         >> $virtual_host_file;
echo -e "\t</Directory>"                >> $virtual_host_file;
echo "ProxyPreserveHost On"             >> $virtual_host_file;

echo "ProxyPass /changed-context balancer://mycluster">> $virtual_host_file;
echo "</VirtualHost>"                   >> $virtual_host_file;


# Change virtualhost port of httpd
sed -ie "s/\(Listen[^0-9]*\)[0-9]*/\1 8080/" /etc/httpd/conf/httpd.conf

# Restart httpd to load new settings
service httpd restart

# A little notification
echo -e " Web server running on $SERVER_IP, \n Please change your hosts file to point $site_name to $SERVER_IP";

