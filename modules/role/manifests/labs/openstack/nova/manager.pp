# This is the wikitech UI
class role::labs::openstack::nova::manager {
    system::role { $name: }
    include ::nutcracker::monitoring
    include ::mediawiki::packages::php5
    include ::mediawiki::packages::math
    include ::mediawiki::packages::tex
    include ::mediawiki::cgroup
    include ::scap::scripts
    include ::openstack::clientlib

    include role::labs::openstack::nova::common
    $novaconfig = $role::labs::openstack::nova::common::novaconfig

    $sitename = hiera('labs_osm_host')
    $sitename_split = split($sitename, '\.')
    $certificate = $sitename_split[0]
    letsencrypt::cert::integrated { $certificate:
        subjects   => $sitename,
        puppet_svc => 'apache2',
        system_svc => 'apache2',
    }

    sslcert::certificate { $sitename: ensure => absent }

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => "check_ssl_http_letsencrypt!${sitename}",
    }

    $ssl_settings = ssl_ciphersuite('apache', 'compat', true)

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
    $keystone_host = hiera('labs_keystone_host')
    ferm::service { 'mysql_keystone':
        proto  => 'tcp',
        port   => '3306',
        srange => "@resolve(${keystone_host})",
    }

    class { '::openstack::openstack_manager':
        novaconfig         => $novaconfig,
        webserver_hostname => $sitename,
        certificate        => $certificate,
    }

    # T89323
    monitoring::service { 'wikitech-static-sync':
        description   => 'are wikitech and wt-static in sync',
        check_command => 'check_wikitech_static',
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
}

