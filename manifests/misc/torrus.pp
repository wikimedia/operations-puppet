# misc/torrus.pp

class misc::torrus {
<<<<<<< HEAD
    system::role { 'misc::torrus':
        description => 'Torrus',
    }

    package { 'torrus-common':
            ensure => latest,
=======
    system::role { 'misc::torrus': description => 'Torrus' }

    package { 'torrus-common':
        ensure => latest;
>>>>>>> dbcda57... Fixed spacing and lint rules for manifests/misc files.
    }

    class web {
        package { 'torrus-apache2':
<<<<<<< HEAD
            ensure => latest,
            before => Service['apache2'],
=======
            before => Service['apache2'],
            ensure => latest
>>>>>>> dbcda57... Fixed spacing and lint rules for manifests/misc files.
        }

        include ::apache::mod::rewrite
        include ::apache::mod::perl

        @webserver::apache::site { 'torrus.wikimedia.org':
            require  => Class['::apache::mod::rewrite', '::apache::mod::perl'],
            docroot  => '/var/www',
<<<<<<< HEAD
            custom   => ['RedirectMatch ^/$ /torrus'],
            includes => ['/etc/torrus/torrus-apache2.conf'],
=======
            custom   => ["RedirectMatch ^/ /torrus"],
            includes => ['/etc/torrus/torrus-apache2.conf']
>>>>>>> dbcda57... Fixed spacing and lint rules for manifests/misc files.
        }
    }

    class config {
        File { require => Package['torrus-common'] }

<<<<<<< HEAD
        file { '/etc/torrus/conf/':
            source  => 'puppet:///files/torrus/conf/',
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            recurse => remote,
        }

        file { '/etc/torrus/templates/':
            source  => 'puppet:///files/torrus/templates/',
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            recurse => remote,
        }

        file { '/usr/share/torrus/sup/webplain/wikimedia.css':
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => 'puppet:///files/torrus/wikimedia.css',
        }
    }

    exec { 'torrus clearcache':
        command     => '/usr/sbin/torrus clearcache',
        require     => Class['misc::torrus::config'],
        subscribe   => Class['misc::torrus::config'],
        logoutput   => true,
        refreshonly => true,
        before      => Exec['torrus compile'],
    }

    exec { 'torrus compile':
        command     => '/usr/sbin/torrus compile --all',
        require     => Class[['misc::torrus::config',
                            'misc::torrus::xmlconfig']
                        ],
        subscribe   => Class[['misc::torrus::config',
                            'misc::torrus::xmlconfig']
                        ],
        logoutput   => true,
        refreshonly => true,
    }

    service { 'torrus-common':
        ensure     => running,
        require    => Exec['torrus compile'],
        subscribe  => File[ ['/etc/torrus/conf/',
                            '/etc/torrus/templates/']
                        ],
        hasrestart => false,
=======
        file {
        '/etc/torrus/conf/':
            source  => 'puppet:///files/torrus/conf/',
            owner   => root,
            group   => root,
            mode    => '0444',
            recurse => remote;
        '/etc/torrus/templates/':
            source  => 'puppet:///files/torrus/templates/',
            owner   => root,
            group   => root,
            mode    => '0444',
            recurse => remote;
        '/usr/share/torrus/sup/webplain/wikimedia.css':
            owner  => root,
            group  => root,
            mode   => '0444',
            source => 'puppet:///files/torrus/wikimedia.css';
        }
    }

    exec {
    'torrus clearcache':
        command     => '/usr/sbin/torrus clearcache',
        require     => Class[misc::torrus::config],
        subscribe   => Class[misc::torrus::config],
        logoutput   => true,
        refreshonly => true,
        before      => Exec['torrus compile'];
    'torrus compile':
        command     => '/usr/sbin/torrus compile --all',
        require     => Class[ [misc::torrus::config, misc::torrus::xmlconfig] ],
        subscribe   => Class[ [misc::torrus::config, misc::torrus::xmlconfig] ],
        logoutput   => true,
        refreshonly => true
    }

    service { 'torrus-common':
        require    => Exec['torrus compile'],
        subscribe  => File[ ['/etc/torrus/conf/', '/etc/torrus/templates/']],
        hasrestart => false,
        ensure     => running;
>>>>>>> dbcda57... Fixed spacing and lint rules for manifests/misc files.
    }

    class xmlconfig {
        require misc::torrus::config
        include passwords::network

<<<<<<< HEAD
        file { '/etc/torrus/xmlconfig/':
            source  => 'puppet:///files/torrus/xmlconfig/',
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            recurse => remote,
        }

        file { '/etc/torrus/xmlconfig/site-global.xml':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('torrus/site-global.xml.erb'),
=======
        file {
        '/etc/torrus/xmlconfig/':
            source  => 'puppet:///files/torrus/xmlconfig/',
            owner   => root,
            group   => root,
            mode    => '0444',
            recurse => remote;
        '/etc/torrus/xmlconfig/site-global.xml':
            owner   => root,
            group   => root,
            mode    => '0444',
            content => template('torrus/site-global.xml.erb');
>>>>>>> dbcda57... Fixed spacing and lint rules for manifests/misc files.
        }
    }

    class discovery {
<<<<<<< HEAD
        require misc::torrus::config
        require misc::torrus::xmlconfig
=======
        require misc::torrus::config, misc::torrus::xmlconfig
>>>>>>> dbcda57... Fixed spacing and lint rules for manifests/misc files.

        # Definition: misc::torrus::discovery
        #
        # This definition generates a torrus discovery DDX file, which Torrus
        # will use to compile its XML config files from SNMP
        #
        # Parameters:
<<<<<<< HEAD
        #   - $subtree: the Torrus subtree path used in the XML config file
        #   - $domain: The domain name to use for SNMP host names
        #   - $snmp_community: The SNMP community needed to query
        #   - $hosts: A list of hosts
        define ddxfile(
            $subtree,
            $domain= '',
            $snmp_community= 'public',
            $hosts= []
        ) {
            file { "/etc/torrus/discovery/${title}.ddx":
                require => File['/etc/torrus/discovery'],
                content => template('torrus/generic.ddx.erb'),
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
                before  => Exec['torrus-discovery'],
                notify  => Exec['torrus-discovery'],
            }
        }

        file { '/etc/torrus/discovery':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0750',
        }

        file { '/etc/cron.daily/torrus-discovery':
            source => 'puppet:///files/torrus/torrus-discovery',
            owner  => 'root',
            group  => 'root',
            mode   => '0550',
=======
        # 	- $subtree: the Torrus subtree path used in the XML config file
        # 	- $domain: The domain name to use for SNMP host names
        # 	- $snmp_community: The SNMP community needed to query
        # 	- $hosts: A list of hosts
        define ddxfile($subtree, $domain='', $snmp_community='public', $hosts=[]) {
            file { "/etc/torrus/discovery/${title}.ddx":
                require => File['/etc/torrus/discovery'],
                content => template('torrus/generic.ddx.erb'),
                owner   => root,
                group   => root,
                mode    => '0444',
                before  => Exec[torrus-discovery],
                notify  => Exec[torrus-discovery];
            }
        }

        file {
        '/etc/torrus/discovery':
            owner  => root,
            group  => root,
            mode   => '0750',
            ensure => directory;
        '/etc/cron.daily/torrus-discovery':
            source => 'puppet:///files/torrus/torrus-discovery',
            owner  => root,
            group  => root,
            mode   => '0550';
>>>>>>> dbcda57... Fixed spacing and lint rules for manifests/misc files.
        }

        exec { 'torrus-discovery':
            require     => File['/etc/cron.daily/torrus-discovery'],
            command     => '/etc/cron.daily/torrus-discovery',
            timeout     => 1800,
            refreshonly => true,
<<<<<<< HEAD
            before      => Exec['torrus compile'],
=======
            before      => Exec['torrus compile'];
>>>>>>> dbcda57... Fixed spacing and lint rules for manifests/misc files.
        }
    }

    class xml-generation {
        # Class: misc::torrus::xml-generation::cdn
        #
        # This class automatically generates XML files for
        # Squid and Varnish servers
        #
        # Uses role/cache/cache.pp
        class cdn {
            require role::cache::configuration

            File {
<<<<<<< HEAD
                owner  => 'root',
                group  => 'root',
                mode   => '0444',
                notify => Exec['torrus compile --tree=CDN'],
            }
            file { '/etc/torrus/xmlconfig/varnish.xml':
                content => template('torrus/varnish.xml.erb'),
            }

            file { '/etc/torrus/xmlconfig/squid.xml':
                content => template('torrus/squid.xml.erb'),
            }

            file { '/etc/torrus/xmlconfig/cdn-aggregates.xml':
                content => template('torrus/cdn-aggregates.xml.erb'),
=======
                owner => root,
                group => root,
                mode => 0444,
                notify => Exec['torrus compile --tree=CDN']
            }
            file {
            '/etc/torrus/xmlconfig/varnish.xml':
                content => template('torrus/varnish.xml.erb');
            '/etc/torrus/xmlconfig/squid.xml':
                content => template('torrus/squid.xml.erb');
            '/etc/torrus/xmlconfig/cdn-aggregates.xml':
                content => template('torrus/cdn-aggregates.xml.erb');
>>>>>>> dbcda57... Fixed spacing and lint rules for manifests/misc files.
            }

            exec { 'torrus compile --tree=CDN':
                path        => '/bin:/sbin:/usr/bin:/usr/sbin',
                logoutput   => true,
<<<<<<< HEAD
                refreshonly => true,
=======
                refreshonly => true;
>>>>>>> dbcda57... Fixed spacing and lint rules for manifests/misc files.
            }
        }
    }

<<<<<<< HEAD
    include xmlconfig
    include discovery
=======
    include xmlconfig, discovery
>>>>>>> dbcda57... Fixed spacing and lint rules for manifests/misc files.
}
