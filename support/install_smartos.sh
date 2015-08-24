#!/bin/sh

## Install PKG-SRC if not present
if [ ! -d /opt/local ]; then
  echo "nameserver 114.114.114.114" >> /etc/resolv.conf
  cd /
##curl -sk https://pkgsrc.joyent.com/packages/SmartOS/bootstrap/bootstrap-2015Q1-x86_64.tar.gz | gzcat | tar -xvf -
  wget --no-check-certificate https://pkgsrc.joyent.com/packages/SmartOS/bootstrap/bootstrap-2015Q1-x86_64.tar.gz
  gzcat bootstrap-2015Q1-x86_64.tar.gz | tar -xvf -
  /opt/local/sbin/pkg_admin rebuild
  /opt/local/bin/pkgin -y up
fi

# Install Ruby & Gems
if [ ! -f /opt/local/bin/chef-client ]; then
    /opt/local/bin/pkgin -y install gcc47 gcc47-runtime gmake ruby200-base ruby200-mime-types ruby200-yajl-ruby ruby200-nokogiri ruby200-readline ruby200-ohai ruby200-chef coreutils pkg-config
    echo "gemhome: /var/.gem" >> /root/.gemrc
    gem sources -r https://rubygems.org/
    gem sources -a http://ruby.taobao.org
    #gem install omnibus
fi

# augment path in an attempt to find a download program
PATH="${PATH}:/smartdc/bin:/opt/smartdc/bin:/opt/local/bin:/opt/local/sbin:/opt/smartdc/agents/bin";
export PATH;
