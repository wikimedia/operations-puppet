# = Class: toollabs::checker
#
# Exposes a set of web endpoints that perform an explicit check for a
# particular set of internal services, and response OK (200) or not (anything else)
# Used for external monitoring / collection of availability metrics
#
# This runs as an ldap user, toolschecker, so it can touch NFS without causing
# idmapd related issues.
class toollabs::checker inherits toollabs {
    include gridengine::submit_host
    include toollabs::infrastructure

    require_package('python-flask',
                    'python-psycopg2',
                    'python-pymysql',
                    'python-redis',
                    'uwsgi',
                    'uwsgi-plugin-python')

    file { '/usr/local/bin/webservice2':
        ensure  => present,
        source  => 'puppet:///modules/toollabs/webservice2',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => Package['python-yaml'], # Present on all hosts, defined for puppet diamond collector
    }

    file { '/usr/local/bin/webservice':
        ensure  => link,
        target  => '/usr/local/bin/webservice2',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => File['/usr/local/bin/webservice2'],
    }

    file { '/usr/local/lib/python2.7/dist-packages/toolschecker.py':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/toollabs/toolschecker.py',
        notify => Service['toolschecker'],
    }

    file { '/data/project/toolschecker/www/python/src/app.py':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/toolschecker_generic_service.py',
        notify => Service['toolschecker'],
    }

    file { '/data/project/toolschecker/public_html/index.php':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/toolschecker_lighttpd_service.php',
        notify => Service['toolschecker'],
    }

    file { ['/run/toolschecker', '/var/lib/toolschecker', '/var/lib/toolschecker/puppetcerts']:
        ensure => directory,
        owner  => "${::labsproject}.toolschecker",
        group  => 'www-data',
        mode   => '0755',
    }

    # We need this host's puppet cert and key (readable) so we can check
    #  puppet status
    file { '/var/lib/toolschecker/puppetcerts/cert.pem':
        ensure => present,
        owner  => "${::labsproject}.toolschecker",
        group  => 'www-data',
        mode   => '0400',
        source => "/var/lib/puppet/ssl/certs/${::fqdn}.pem"
    }
    file { '/var/lib/toolschecker/puppetcerts/key.pem':
        ensure => present,
        owner  => "${::labsproject}.toolschecker",
        group  => 'www-data',
        mode   => '0400',
        source => "/var/lib/puppet/ssl/private_keys/${::fqdn}.pem"
    }

    file { '/etc/init/toolschecker.conf':
        ensure  => present,
        content => template('toollabs/toolschecker.upstart.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Service['toolschecker'],
    }

    service { 'toolschecker':
        ensure  => running,
        require => File['/run/toolschecker'],
    }


    nginx::site { 'toolschecker-nginx':
        require => Service['toolschecker'],
        content => template('toollabs/toolschecker.nginx.erb'),
    }
}
