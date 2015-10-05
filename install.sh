#! /bin/sh

set -x

script_root=$(cd $(dirname $0) && pwd)

repo_root=https://raw.githubusercontent.com/mao172/cc-installer
branch_nm=master

hw_platform=$(uname -i)

if [ -f /etc/redhat-release ]; then
  platform_family="rhel"
  platform=$(cat /etc/redhat-release | awk '{print $1}')
  platform_version=$(cat /etc/redhat-release | awk '{print $3}')
fi

ge() {
  ret=$(echo $1 $2 | awk '{printf ("%d", $1>=$2)}')
  test ${ret} -eq 1
  return $?
}

packer_install() {
  if [ -f ${script_root}/lib/install_packer.sh ]; then
    cat ${script_root}/lib/install_packer.sh | bash -s -- -v 0.7.5
  else
    curl -L ${repo_root}/${branch_nm}/lib/install_packer.sh | bash -s -- -v 0.7.5
  fi
}

postgresql_install() {
  local version=9.4

  if [ -f ${script_root}/lib/install_postgresql.sh ]; then
    cat ${script_root}/lib/install_postgresql.sh | bash -s -- -v ${version}
  else
    curl -L ${repo_root}/${branch_nm}/lib/install_postgresql.sh | bash -s -- -v ${version}
  fi

  export PATH=$PATH:/usr/pgsql-${version}/bin
  expect -c "
  spawn sudo -u postgres LANG=C createuser --createdb --encrypted --pwprompt ${db_user}
  expect \"Enter password for new role:\"
  send -- \"${db_pswd}\n\"
  expect \"Enter it again:\"
  send -- \"${db_pswd}\n\"
  "
}

ruby_install() {
  local version=2.1.5
  local ruby_home=/opt/cloud_conductor/ruby

  if ! which git > /dev/null 2>&1; then
    yum install -y git
  fi

  yum install -y gcc gcc-c++ make patch openssl-devel readline-devel zlib-devel

  if [ -f ${script_root}/lib/install_ruby.sh ]; then
    cat ${script_root}/lib/install_ruby.sh | bash -s -- -v ${version} -d ${ruby_home}
  else
    curl -L ${repo_root}/${branch_nm}/lib/install_ruby.sh | bash -s -- -v ${version} -d ${ruby_home}
  fi

  export PATH=$PATH:${ruby_home}/bin
  gem install bundler || return $?
}

cc_install() {

  yum install -y gcc gcc-c++ make patch libxslt-devel libxml2-devel

  git clone https://github.com/cloudconductor/cloud_conductor.git /opt/cloud_conductor
  cd /opt/cloud_conductor
  if ! [ "${branch}" == "" ]; then
    git checkout ${branch}
  fi

  ruby_install || return $?
  bundle install

  cp config/config.rb.smp config/config.rb

}

if ! which wget > /dev/null 2>&1; then
  yum install -y wget
fi

if ! which unzip > /dev/null 2>&1; then
  yum install -y unzip
fi

if ! which expect > /dev/null 2>&1; then
  yum install -y expect
fi

db_user="conductor"
db_pswd="password"

branch=""
config_file="${script_root}/config/install.cfg"

while getopts v:b:c: OPT
do
  case $OPT in
    "v" ) 
      VERSION="$OPTARG"
      ;;
    "b" )
      branch="$OPTARG"
      ;;
    "c" )
      config_file="$OPTARG"
      ;;
  esac
done

packer_install

postgresql_install

cc_install
