#! /bin/sh

set -x

CC_HOME=/opt/cloud_conductor

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
  local version=0.7.5
  version=$1

  if [ -f ${script_root}/lib/install_packer.sh ]; then
    cat ${script_root}/lib/install_packer.sh | bash -s -- -v ${version}
  else
    curl -L ${repo_root}/${branch_nm}/lib/install_packer.sh | bash -s -- -v ${version}
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
}

ruby_install() {
  local version=2.1.5
  local ruby_home=/opt/cloud_conductor/ruby

  if ! which git > /dev/null 2>&1; then
    yum install -y git
  fi

  if [ ! -d ${ruby_home} ]; then
    yum install -y gcc gcc-c++ make patch openssl-devel readline-devel zlib-devel

    if [ -f ${script_root}/lib/install_ruby.sh ]; then
      cat ${script_root}/lib/install_ruby.sh | bash -s -- -v ${version} -d ${ruby_home}
    else
      curl -L ${repo_root}/${branch_nm}/lib/install_ruby.sh | bash -s -- -v ${version} -d ${ruby_home}
    fi
  fi

  export PATH=$PATH:${ruby_home}/bin
  gem install bundler || return $?
}

cc_install() {
  local version=1.1.0
  version=$1

  if [ ! -d ${CC_HOME} ]; then
    git clone https://github.com/cloudconductor/cloud_conductor.git ${CC_HOME}
  fi

  cd ${CC_HOME}
  if ! [ "${branch}" == "" ]; then
    git checkout ${branch}
  fi

  ruby_install || return $?
  bundle install

}

cc_settings() {
  cd ${CC_HOME}
  cp config/config.rb.smp config/config.rb

  sed -i\
    -e "s@cloudconductor.url .*@cloudconductor.url 'http://localhost/api/v1'@g"\
    -e "s/dns.access_key .*/dns.access_key '${aws_access_key}'/g"\
    -e "s/dns.secret_key .*/dns.secret_key '${aws_secret_key}'/g"\
    config/config.rb

  secret_key_base=$(bundle exec rake secret)
  sed -i.org -e "s/secret_key_base: .*/secret_key_base: ${secret_key_base}/g" config/secrets.yml
  sed -i.org -e "s/# config.secret_key = '.*'/config.secret_key = '${secret_key_base}'/" config/initializers/devise.rb
}

db_settings() {
  expect -c "
  spawn sudo -u postgres LANG=C createuser --createdb --encrypted --pwprompt ${db_user}
  expect \"Enter password for new role:\"
  send -- \"${db_pswd}\n\"
  expect \"Enter it again:\"
  send -- \"${db_pswd}\n\"
  expect \"]$ \"
  "

  cd ${CC_HOME}
  cp config/database.yml.smp config/database.yml
  sed -i\
    -e "s/username: .*/username: ${db_user}/g"\
    -e "s/password: .*/password: ${db_pswd}/g"\
    config/database.yml

}

create_db() {
  bundle exec rake db:create
  bundle exec rake db:migrate
}

create_admin_user() {
  expect -c "
  spawn bundle exec rake register:admin
  expect \"Email:\"
  send -- \"${admin_email}\n\"
  expect \"Name:\"
  send -- \"${admin_name}\n\"
  expect \"Password:\"
  send -- \"${admin_pswd}\n\"
  expect \"Password Confirmation:\"
  send -- \"${admin_pswd}\n\"
  expect \"]$ \"
  "
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

aws_access_key="***access-key***"
aws_secret_key="***secret-key***"

admin_email="admin@example.com"
admin_name="cc-admin"
admin_pswd="password"

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

packer_install 0.8.6

postgresql_install

cc_install 1.1.0

cc_settings

db_settings

create_db

create_admin_user
