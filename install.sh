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

  if ! which git > /dev/null 2>&1; then
    yum install -y git
  fi

  yum install -y gcc gcc-c++ make patch openssl-devel readline-devel zlib-devel

  if [ ! -d /usr/local/rbenv ]; then
    git clone https://github.com/sstephenson/rbenv.git /usr/local/rbenv
    git clone https://github.com/sstephenson/ruby-build.git /usr/local/rbenv/plugins/ruby-build
  fi

#  rbenv init -
  tee /etc/profile.d/rbenv.sh > /dev/null <<'EOF'
export RBENV_ROOT=/usr/local/rbenv
export PATH=$PATH:$RBENV_ROOT/bin
eval "$(rbenv init -)"
EOF

  source /etc/profile.d/rbenv.sh
  rbenv install ${version} #|| return $?
  rbenv global ${version}
  rbenv rehash
  gem install bundler || return $?
}

cc_install() {
  ruby_install || return $?

  yum install -y gcc gcc-c++ make patch libxslt-devel libxml2-devel

  git clone https://github.com/cloudconductor/cloud_conductor.git /opt/cloud_conductor
  cd /opt/cloud_conductor
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

db_user="cc_user"
db_pswd="cc_pswd"

while getopts v: OPT
do
  case $OPT in
    "v" ) VERSION="$OPTARG";;
  esac
done

packer_install

postgresql_install

cc_install
