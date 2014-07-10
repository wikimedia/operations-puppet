# Class: toollabs::webnode
#
# This role sets up an web node in the Tool Labs model.
#
# Parameters:
#       gridmaster => FQDN of the gridengine master
#       type => What kind of web server to set up
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::webnode($gridmaster, $type) inherits toollabs {
    include toollabs::exec_environ,
        toollabs::infrastructure,
        toollabs::gridnode

    class { 'gridengine::exec_submit_host':
        gridmaster => $gridmaster,
    }

    class { 'toollabs::hba':
        store => $store,
    }

    file { "${store}/execnode-${::fqdn}":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File[$store],
        content => "${::ipaddress}\n",
    }

    case $type {
        lighttpd: {
            package { 'php5-cgi':
                ensure => latest,
            }

            package { 'lighttpd':
                ensure => latest,
                require => File['/var/run/lighttpd'],
            }

            file { '/var/run/lighttpd':
                ensure => directory,
                owner  => 'www-data',
                group  => 'www-data',
                mode   => '01777',
            }
        }
        tomcat: {
            package { 'tomcat7-user':
                ensure => latest,
            }
            package { 'xmlstarlet':
                ensure => latest,
                before => File['/usr/local/bin/tomcat-starter'],
            }
        }
    }

    file { "/usr/local/bin/tool-${type}":
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => "puppet:///modules/toollabs/tool-${type}",
    }

    file { "/usr/local/bin/${type}-starter":
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => "puppet:///modules/toollabs/${type}-starter",
    }

    file { '/usr/local/bin/portgrabber':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/portgrabber',
    }

    file { '/usr/local/sbin/portgranter':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/portgranter',
    }

    file { '/etc/init/portgranter.conf':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/toollabs/portgranter.conf',
    }
}
