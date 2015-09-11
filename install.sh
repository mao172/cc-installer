#! /bin/sh

set -x

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
  local install_dir=/opt/packer
  if [ ! -d ${install_dir} ]; then
    mkdir -p ${install_dir}
  fi

  if [ ! -f ${install_dir}/packer ]; then
    file_name="packer_${version}_linux_386.zip"
    if [ "${hw_platform}" == "x86_64" ]; then
      file_name="packer_${version}_linux_amd64.zip"
    fi

    cd ${install_dir}
    wget -N https://dl.bintray.com/mitchellh/packer/${file_name} || return $?
    unzip ${file_name} -d /opt/packer
  fi
}

postgresql_install() {
  local version=9.4
  local os_name=${platform,,}
  local platform_family=redhat
  local platform=rhel-6-${hw_platform}
  if ge ${platform_version} 7; then
    platform=rhel-7-${hw_platform}
  fi
  local file_name="pgdg-${os_name}${version/./}-${version}-1.noarch.rpm"
  local pkg_name=postgresql${version/./}
  local svc_name=postgresql-${version}

#  http://yum.postgresql.org/9.4/redhat/rhel-6-x86_64/pgdg-centos94-9.4-1.noarch.rpm
#  http://yum.postgresql.org/9.4/redhat/rhel-6-i386/pgdg-centos94-9.4-1.noarch.rpm
  yum install -y http://yum.postgresql.org/${version}/${platform_family}/${platform}/${file_name}
  yum install -y ${pkg_name}-server ${pkg_name}-contrib ${pkg_name}-devel
  service ${svc_name} initdb

  sed -i \
    -e 's@^\(host *all *all *127.0.0.1\/32 *\).*@\1md5@' \
    -e 's@^\(host *all *all *::1\/128 *\).*@\1md5@' \
    /var/lib/pgsql/${version}/data/pg_hba.conf

  service ${svc_name} start

  export PATH=$PATH:/usr/pgsql-${version}/bin
  expect -c "
  spawn sudo -u postgres createuser --createdb --encrypted --pwprompt ${db_user}
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

  rbenv init -
  tee /etc/profile.d/rbenv.sh > /dev/null <<'EOF'
export RBENV_ROOT=/usr/local/rbenv
export PATH=$PATH:$RBENV_ROOT/bin
eval "$(rbenv init -)"
EOF

  source /etc/profile.d/rbenv.sh
  rbenv install ${version} || return $?
  rbenv global ${version}
  rbenv rehash
  gem install bundler
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

packer_install

postgresql_install

cc_install
