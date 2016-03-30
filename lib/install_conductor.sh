#!/bin/sh

set -x

CC_HOME=/opt/cloud_conductor

if [ -x $script_root ]; then
  script_root=$(pwd)
fi

install_cc() {
  local version=1.1.0
  version=$1

  if ! which git > /dev/null 2>&1; then
    yum install -y git
  fi

  if [ ! -d ${CC_HOME} ]; then
    git clone https://github.com/cloudconductor/cloud_conductor.git ${CC_HOME}
  fi

  cd ${CC_HOME}
  if ! [ "${branch}" == "" ]; then
    git checkout ${branch}
  fi
}

setup_ruby() {
  local version=2.1.5
  local ruby_home=/opt/cloud_conductor/ruby
  version=$1 ruby_home=$2

  if [ ! -d ${ruby_home} ]; then
    if [ -f ${script_root}/lib/install_ruby.sh ]; then
      cat ${script_root}/lib/install_ruby.sh | bash -s -- -v ${version} -d ${ruby_home}
    else
      curl -L ${repo_root}/${branch_nm}/lib/install_ruby.sh | bash -s -- -v ${version} -d ${ruby_home}
    fi
  fi

  export PATH=$PATH:${ruby_home}/bin
}

install_cc-cli() {
  local version=1.1.0
  local cli_home=/opt/cloud_conductor/cli
  version=$1 cli_home=$2

  if [ ! -d $${cli_home} ]; then
    git clone https://github.com/cloudconductor/cloud_conductor_cli.git ${cli_home}
  fi

  cd ${cli_home}
  if [ -n ${branch} ]; then
    git checkout ${branch}
  fi

  bundle install
  bundle exec rake install
}

VERSION=1.1.0

while getopts d:v: OPT
do
  case $OPT in
    "d" )
      CC_HOME="$OPTARG"
      ;;
    "v" )
      VERSION="$OPTARG"
      ;;
  esac
done


install_cc ${VERSION}
setup_ruby 2.1.5 ${CC_HOME}/ruby
install_cc-cli ${VERSION} ${CC_HOME}/cli
