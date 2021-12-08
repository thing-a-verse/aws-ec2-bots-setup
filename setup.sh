#!/usr/bin/bash
#
# aws-ecw-bots-setup
#
# build a splunk instance for a BOTS type activity
#


# Wrapper for logger to provide some highlight
function headline_logger () {
  MSG=$2
  echo "*********************************************************************************************"
  /bin/logger -s ${2}
  echo "*********************************************************************************************"
}

# Root commands - pre service account, fetch packages, configure DB & Caching Server
function root_pre() {
  SVC=${1}
  headline_logger -s "Start ${0} installation as `whoami`"
  logger -s "pwd=`pwd`"

  # Disable SELinux
  CONFIG=/etc/selinux/config
  logger -s "Update the SELinux config file $CONFIG: configure SELINUX=permissive"
  sed -i "s|SELINUX=enforcing|SELINUX=permissive|g" $CONFIG
  # Disable immediately
  setenforce 0

  # Git is already installed, else how did we get here? Well, just in case...
  headline_logger -s "Installing git"
  sudo yum install git -y

  # Handy for fetching splunk rpm file
  headline_logger -s "Installing wget"
  sudo yum install wget -y

  logger -s "Fetch splunk 8.2.3"
  # splunk 8.2.2.3
  PACKAGE=splunk-8.2.3-cd0848707637-linux-2.6-x86_64.rpm

  wget -nv -O $PACKAGE 'https://download.splunk.com/products/splunk/releases/8.2.3/linux/splunk-8.2.3-cd0848707637-linux-2.6-x86_64.rpm'
  #https://download.splunk.com/products/splunk/releases/8.2.3/linux/splunk-8.2.3-cd0848707637-linux-2.6-x86_64.rpm.md5?_ga=2.171938210.305817112.1638779062-1114357162.1631187882&_gac=1.219988587.1638779791.CjwKCAiAhreNBhAYEiwAFGGKPKEFXeiECB0VRg8cul9UtOYWmTcVqU0IaZVFn_P0ggCJ73UmRJc-yxoCu6gQAvD_BwE&_gl=1*1hhvf2e*_gcl_aw*R0NMLjE2Mzg3NzkzMjguQ2p3S0NBaUFocmVOQmhBWUVpd0FGR0dLUEtFRlhlaUVDQjBWUmc4Y3VsOVV0T1lXbVRjVnFVMElhWlZGbl9QMGdnQ0o3M1VtUkpjLXl4b0N1NmdRQXZEX0J3RQ..

  # splunk 8.2.2.2
  #wget -O splunk-8.2.2.2-e89a7a0a7f22-linux-2.6-x86_64-fips.rpm 'https://download.splunk.com/products/splunk/releases/8.2.2.2/linux/splunk-8.2.2.2-e89a7a0a7f22-linux-2.6-x86_64-fips.rpm'
  #https://download.splunk.com/products/splunk/releases/8.2.2.2/linux/splunk-8.2.2.2-e89a7a0a7f22-linux-2.6-x86_64-fips.rpm.md5

  logger -s "Install splunk enterprise"
  sudo yum install $PACKAGE -y

  # This has the NET effect of creating an account called 'splunk'
  # Our service account is also 'splunk' - so when we configure, we will configure in the non-priv account


}

# Root commands - post service account, configure and start apache
function root_post() {
  SVC=${1}
  headline_logger -s "Start ${0} installation as `whoami`"
  # Steps to run as root after main

}

# SVC commands - run as unpriv user, install main application
function main() {

  headline_logger -s "Start ${0} installation as `whoami`"
  SVC=${1}


  logger -s "PATH=`echo $PATH`"
  logger -s "Start splunk and accept the EULA"

  USER=admin
  PASS=password123
  # default user is admin
  splunk start --accept-license --answer-yes --no-prompt --seed-passwd $PASS


  headline_logger -s "Configure some users, indexes and basic configuration"

  splunk login -auth $USER:$PASS

  # create alice
  USER=alice
  PASS=password123
  ROLE=user
  DOMAIN=acme.com
  NAME="Alice"
  logger -s "Create user $USER"
  splunk add user $USER -password $PASS -role $ROLE -email $USER@$DOMAIN -full-name $NAME -force-change-pass true

  # Create bob
  USER=bob
  NAME="Robert"
  logger -s "Create user $USER"
  splunk add user $USER -password $PASS -role $ROLE -email $USER@$DOMAIN -full-name $NAME -force-change-pass true

  # Create index
  INDEX_NAME=apache
  INDEX_MAX=100
  logger -s "Create index $INDEX_NAME"
  # https://docs.splunk.com/Documentation/Splunk/8.2.3/Indexer/Configureindexstorage
  splunk add index $INDEX_NAME -maxTotalDataSizeMB $INDEX_MAX


  # Import some data
  LOGDATA=apache.log
  HOSTNAME=grumpy
  SOURCE=/var/log/httpd/error_log
  SOURCETYPE="apache:error"
  logger -s "Fetching some sample data into $LOGDATA"
  wget -nv -O $LOGDATA https://github.com/logpai/loghub/blob/master/Apache/Apache_2k.log

  logger -s "Loading $LOGDATA into $INDEX_NAME "
  splunk add oneshot $LOGDATA -index $INDEX_NAME -hostname $HOSTNAME -rename-source $SOURCE -sourcetype $SOURCETYPE

  # Create index
  INDEX_NAME=windows
  INDEX_MAX=100
  logger -s "Create index $INDEX_NAME"
  splunk add index $INDEX_NAME -maxTotalDataSizeMB $INDEX_MAX

}

SVC=${2:-ctfd}
headline_logger -s "setup.sh: $1 $2 (SVC=${SVC})"
case $1 in
  "pre"*)
  root_pre $SVC
  ;;
  "post"*)
  root_post $SVC
  ;;
  "main"*)
  main $SVC
  ;;
  *)
  main
  ;;
esac
headline_logger -s "setup.sh: done"
echo "Done"
