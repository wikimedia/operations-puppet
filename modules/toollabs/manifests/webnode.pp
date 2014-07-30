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

    # should be exec_host and submit_host
    # [bleep] puppet
    class { 'gridengine::exec_submit_host':
        gridmaster => $gridmaster,
    }

    file { "${store}/execnode-${::fqdn}":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File[$store],
        content => "${::ipaddress}\n",
    }

    # Execution hosts have funky access requirements; they need to be ssh-able
    # by service accounts, and they need to use host-based authentication.

    # We override /etc/ssh/shosts.equiv and /etc/security/access.conf
    # accordingly from information collected from the project store.

    file { '/usr/local/sbin/project-make-shosts':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/toollabs/project-make-shosts',
    }

    exec { 'make-shosts':
        command => '/usr/local/sbin/project-make-shosts >/etc/ssh/shosts.equiv~',
        require => File['/usr/local/sbin/project-make-shosts', $store],
    }

    file { '/etc/ssh/shosts.equiv':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => '/etc/ssh/shosts.equiv~',
        require => Exec['make-shosts'],
    }

    file { '/usr/local/sbin/project-make-access':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/toollabs/project-make-access',
    }

    exec { 'make-access':
        command => '/usr/local/sbin/project-make-access >/etc/security/access.conf~',
        require => File['/usr/local/sbin/project-make-access', $store],
    }

    File <| title == '/etc/security/access.conf' |> {
        content => undef,
        source  => '/etc/security/access.conf~',
        require => Exec['make-access'],
    }

    case $type {
        lighttpd: {
            package { 'php5-cgi':
                ensure => latest,
            }

            package { [
		'lighttpd',
		'lighttpd-mod-magnet',		#Bug 68614
		]:
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

