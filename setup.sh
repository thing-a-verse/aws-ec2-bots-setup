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
