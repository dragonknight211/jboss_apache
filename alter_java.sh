#!/bin/bash
#
# alter_java.sh
#
# Install and set the version of java on Debian system
# This script can be modify to work on other Distro of linux, by changing ALTERNATIVES_COMMAND
#
# The script will download apache maven from Ukrainian mirror, you can select other mirror to suit you by chaing DOWNLOAD_LINK (
#       the verververver portion is version number version numbers must have the same length
#       the bbbbbbbbbbb portion is for the b.... number in Oracle's site (stupid oracle)
#
# The sript will download and extract Oracle java to TARGET_DIR, please change this if you want to
#
#
#
# The list of supported version is in AVAILABLE VERSIONS
#
#: syntax: sudo ./alter_java install|remove version_number
# 
# Check if we have enough parameters
#

ALTERNATIVES_COMMAND="update-alternatives";
TARGET_COMMAND="java";    # Apache maven
DOWNLOAD_LINK="http://download.oracle.com/otn-pub/java/jdk/verververver-bbbbbbbbb/jdk-verververver-linux-x64.tar.gz";
AVAILABLE_VERSIONS=("8u45" "8u40" "8u31" "7u76"); # Remember to update function numeric_version when add new version to this list

#
# Convert version name to numeric format (stupid Oracle)
# When extracted, the files will be in a directory with the name of this numeric format
#
version_num=0;
b_string="";
function numeric_version()
{
    case "$1" in
        8u45)
            version_num="1.8.0_45";
            b_string="b14";
            ;;
        8u40)
            version_num="1.8.0_40";
            b_string="b26";
            ;;
        8u31)
            version_num="1.8.0_31";
            b_string="b13";
            ;;
        7u76)
            version_num="1.7.0_76";
            b_string="b13";
            ;;
        *)
            echo "Cannot convert this version name to numeric representation";
            exit 1;
        ;;
    esac
}
TARGET_DIR="/opt";  # We we will download and extract all the files

# Check if the script is ran as root
if [ `id -u` -ne 0 ]; then
    # Not the root
    echo "Please make sure this script is ran as root!";
    exit 1;
fi

if [ $# != 2 ]; then
    # Not enough
    echo "not enough paramteres";
    exit 1;
fi

version_number=$2;

# Check if the selected version is in the list of available ones
# The case check is not enough ~> Check the length as well
version_length=`echo $version_number | wc -c`;
if [ $version_length != 5 ]; then
    # version number is not long enough
    echo -n "Version not supported. Available versions are "; 
    grep AVAILABLE_VERSIONS $0 | head -n 1;
    exit 1;

fi
case "${AVAILABLE_VERSIONS[@]}" in
    *"$version_number"*)
        echo "  This version is supported";
        ;;
    *)
        echo -n "Version not supported. Available versions are "; 
        grep AVAILABLE_VERSIONS $0 | head -n 1;
        exit 2;
        ;;
esac

if [ "$1" == "install" ]; then
    echo "Trying to install now";
    version_number=$2;
    echo "  Checking if version $version_number is installed";
    numeric_version $version_number;

    # Check if this version is already installed
    install_status=`$ALTERNATIVES_COMMAND --list $TARGET_COMMAND | grep $version_number | wc -l `;
    #echo "install_status --$install_status--";
    if [ $install_status == 0 ]; then
        echo "  Not installed. Trying to install version $version_number of $TARGET_COMMAND now...";
        cd $TARGET_DIR;
		
		 
        url_link=`echo $DOWNLOAD_LINK | sed "s/verververver/$version_number/g" | sed "s/bbbbbbbbb/$b_string/g"`;

        # Where we will put JDK
		file_name="jdk-$version_number-linux-x64.tar.gz"; # File name of the archive
        dir_name="$TARGET_DIR/jdk$version_num"; # Extracted directory (Stupid Oracle)

        # Check and download only if needed
        if [ ! -d $dir_name ]; then
            # Download the file
            wget -O $file_name --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie;" $url_link;

            # Extract
            tar xzvf $file_name;
        fi;

        $ALTERNATIVES_COMMAND --install /usr/bin/java java $dir_name/bin/java 100 \
            --slave /usr/bin/jar jar $dir_name/bin/jar \
            --slave /usr/bin/javac javac $dir_name/bin/javac \
            --slave /usr/bin/javadoc javadoc $dir_name/bin/javadoc \
            --slave /usr/bin/javaws javaws $dir_name/bin/javaws \
            --slave /usr/bin/jcontrol jcontrol $dir_name/bin/jcontrol;

        echo "    Version $version_number of $TARGET_COMMAND installed to alternatives";
    fi

    # Version installed, set $TARGET_COMMAND to selected version
    dir_name="$TARGET_DIR/jdk$version_num";
    $ALTERNATIVES_COMMAND --set $TARGET_COMMAND $dir_name/bin/$TARGET_COMMAND;

    echo "    Done, $TARGET_COMMAND is set to $version_number ($dir_name/bin/$TARGET_COMMAND)";
else 
    if [ "$1" == "remove" ]; then
        echo "   Trying to remove version $version_number from $TARGET_COMMAND now...";
        numeric_version $version_number;
        dir_name="$TARGET_DIR/jdk$version_num";
        $ALTERNATIVES_COMMAND --remove $TARGET_COMMAND $dir_name/bin/$TARGET_COMMAND
        echo "     Version $version_number is removed for $TARGET_COMMAND";
    else
        echo "  Not recognized command: install | remove";
    fi
fi;
