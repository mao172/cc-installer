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

postgresql_install() {
  local version=$1
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

  export PATH=$PATH:/usr/pgsql-${version}/bin

  if ge ${platform_version} 7; then
    /usr/pgsql-${version}/bin/postgresql${version/./}-setup initdb
  else
    service ${svc_name} initdb
  fi

  sed -i \
    -e 's@^\(host *all *all *127.0.0.1\/32 *\).*@\1md5@' \
    -e 's@^\(host *all *all *::1\/128 *\).*@\1md5@' \
    /var/lib/pgsql/${version}/data/pg_hba.conf

  if ge ${platform_version} 7; then
    systemctl enable ${svc_name}
    systemctl start ${svc_name}
  else
    service ${svc_name} start
  fi
}

VERSION=9.4

while getopts v: OPT
do
  case $OPT in
    "v" ) VERSION="$OPTARG";;
  esac
done

postgresql_install $VERSION
