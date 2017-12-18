class profile::openstack::base::wikitech::service(
    $osm_host = hiera('profile::openstack::base::osm_host'),
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    $webserver_hostname_aliases = hiera('profile::openstack::base::wikitech::webserver_hostname_aliases'),
    $wikidb = hiera('profile::openstack::base::wikitech::db_name'),
    $wikitech_nova_ldap_proxyagent_pass = hiera('profile::openstack::base::ldap_proxyuser_pass'),
    $wikitech_nova_ldap_user_pass = hiera('profile::openstack::base::ldap_user_pass'),
    ) {

    include ::nutcracker::monitoring
    include ::profile::prometheus::nutcracker_exporter
    include ::mediawiki::packages::php5
    include ::mediawiki::packages::math
    include ::mediawiki::packages::tex
    include ::mediawiki::cgroup
    include ::scap::scripts

    # Readline support for PHP maintenance scripts (T126262)
    require_package('php5-readline')

    $osm_host_split = split($osm_host, '\.')
    $certificate = $osm_host_split[0]
    letsencrypt::cert::integrated { $certificate:
        subjects   => $osm_host,
        puppet_svc => 'apache2',
        system_svc => 'apache2',
    }

    class { '::openstack::wikitech::openstack_manager':
        certificate                        => $certificate,
        webserver_hostname                 => $osm_host,
        webserver_hostname_aliases         => $webserver_hostname_aliases,
        wikidb                             => $wikidb,
        wikitech_nova_ldap_proxyagent_pass => $wikitech_nova_ldap_proxyagent_pass,
        wikitech_nova_ldap_user_pass       => $wikitech_nova_ldap_user_pass,
    }

    # For Math extensions file (T126628)
    file { '/srv/math-images':
        ensure => 'directory',
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
    }

    # On app servers and image scalers, convert(1) from imagemagick is
    # contained in a firejail profile. Silver receives the same setting
    # in wmf-config/CommonSettings.php via $wgImageMagickConvertCommand
    # and since we also need to scale graphics on wikitech, provide them here
    file { '/usr/local/bin/mediawiki-firejail-convert':
        source => 'puppet:///modules/mediawiki/mediawiki-firejail-convert',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/etc/firejail/mediawiki-converters.profile':
        source => 'puppet:///modules/mediawiki/mediawiki-converters.profile',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    class { '::nutcracker':
        mbuf_size => '64k',
        verbosity => 2,
        pools     => {
            'memcached' => {
                distribution       => 'ketama',
                hash               => 'md5',
                listen             => '127.0.0.1:11212',
                server_connections => 2,
                servers            => [
                    '127.0.0.1:11000:1',
                ],
            },
        },
    }

    ferm::service { 'wikitech_http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'wikitech_https':
        proto => 'tcp',
        port  => '443',
    }

    ferm::service { 'deployment-ssh':
        proto  => 'tcp',
        port   => '22',
        srange => '$DEPLOYMENT_HOSTS',
    }

    # allow keystone to query the wikitech db
    ferm::service { 'mysql_keystone':
        proto  => 'tcp',
        port   => '3306',
        srange => "@resolve(${nova_controller})",
    }
}
