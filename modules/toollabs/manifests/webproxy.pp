# Class: toollabs::webproxy
#
# This role sets up a web proxy in the Tool Labs model.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::webproxy inherits toollabs {
  include toollabs::infrastructure

  #TODO: apache config

  # AWStats infrastructure.
  file { "/usr/local/sbin/awstats-filter.sh":
    ensure => file,
    mode => "0755",
    owner => "root",
    group => "root",
    source => "puppet:///modules/toollabs/awstats/awstats-filter.sh";
  }

  file { "/etc/logrotate.d/httpd-prerotate":
    ensure => directory,
    mode => "0755",
    owner => "root",
    group => "root";
  }

  file { "/etc/logrotate.d/httpd-prerotate/awstats.sh":
    ensure => file,
    mode => "0755",
    owner => "root",
    group => "root",
    require => File["/etc/logrotate.d/httpd-prerotate"],
    source => "puppet:///modules/toollabs/awstats/logrotate";
  }

  file { "/etc/sudoers.d/awstats":
    ensure => file,
    mode => "0440",
    owner => "root",
    group => "root",
    source => "puppet:///modules/toollabs/awstats/sudoers";
  }

  cron { "awstats-update":
    ensure => present,
    minute => 14,
    hour => "*",
    user => local-awstats,
    command => "/data/project/awstats/refresh-awstats.sh";
  }
}
