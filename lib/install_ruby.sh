#! /bin/sh

RUBY_HOME='/usr/local'
VERSION='2.1.5'

packages_install() {
  yum install -y gcc gcc-c++ make patch libxslt-devel libxml2-devel wget tar
}

ruby_install_from_source() {
  local version=$1
  local version_family=${version%.*}

  packages_install

  wget http://cache.ruby-lang.org/pub/ruby/${version_family}/ruby-${version}.tar.gz
  tar xfz ruby-${version}.tar.gz 

  cd ruby-${version}

  ./configure --prefix=${RUBY_HOME}
  make
  make install
}

ruby_install() {

  ruby_install_from_source ${VERSION}
}

while getopts d:v: OPT
do
  case $OPT in
    "d" ) 
      RUBY_HOME="$OPTARG"
      ;;
    "v" ) 
      VERSION="$OPTARG"
      ;;
  esac
done

which ruby
status=$?

if [ $status -ne 0 ]; then
  ruby_install
fi
