# Class: role::toollabs::node::web::lighttpd
#
# This configures the compute node as a lighttpd web server
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# filtertags: labs-project-tools
class role::toollabs::node::web::lighttpd inherits role::toollabs::node::web {

    package { 'php5-cgi':
        ensure => latest,
    }

    package { [
        'lighttpd',
        'lighttpd-mod-magnet',        #T70614
        ]:
        ensure  => latest,
        require => File['/var/run/lighttpd'],
    }

    class { '::toollabs::queues': queues => [ 'webgrid-lighttpd' ] }

    file { '/var/run/lighttpd':
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '1777',
    }

    # Update lighttpd.tmpfile.conf so that systemd doesn't monkey
    #  with the permissions of /var/run/lighttpd as created above
    #  As per T142932
    if os_version('ubuntu >= trusty') or os_version('debian >= jessie') {
        file { '/usr/lib/tmpfiles.d/lighttpd.tmpfile.conf':
            ensure  => present,
            require => Package['lighttpd'],
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            content => "d /var/run/lighttpd 1777 www-data www-data -\n",
        }
    }
}
