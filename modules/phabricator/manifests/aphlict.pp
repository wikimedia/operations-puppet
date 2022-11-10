# == Class: phabricator::aphlict
# Aphlict is the phabricator real-time notification relay service.
# Docs: https://secure.phabricator.com/book/phabricator/article/notifications/
#
# === Parameters
#
# [*ensure*]
#   either present / absent
#
# [*user*]
#   The user account that aphlict runs with
#
# [*group*]
#   Group for the aphlict service
#
# [*basedir*]
#   Phabricator base directory
#
# [*enable_ssl*]
#   should ssl be enabled on the client port. Set to true to terminate
#   tls in aphlict, set to false if tls is terminated in envoy.
#
# [*sslcert*]
#   path to the ssl cert for aphlict
#
# [*sslkey*]
#   path to the ssl certificate private key
#
# [*sslchain*]
#   path to the ssl certificate chain file
#
# [*client_port*]
#   port used for aphlict client connections (default: 22280)
#
# [*client_listen*]
#   IP address to listen on for aphlict client connections (default: 0.0.0.0)
#
# [*admin_port*]
#   port used for the aphlict admin interface (default: 22281)
#
# [*admin_listen*]
#   IP address to listen on for the aphlict admin interface (default: 127.0.0.1)
#
class phabricator::aphlict(
    Wmflib::Ensure $ensure,
    String $user = 'aphlict',
    String $group = 'aphlict',
    Stdlib::Unixpath $basedir = '/srv/phab',
    Boolean $enable_ssl = false,
    Optional[Stdlib::Unixpath] $sslcert = undef,
    Optional[Stdlib::Unixpath] $sslkey = undef,
    Optional[Stdlib::Unixpath] $sslchain = undef,
    Stdlib::Port $client_port = 22280,
    Stdlib::IP::Address $client_listen = '0.0.0.0',
    Stdlib::Port $admin_port = 22281,
    Stdlib::IP::Address $admin_listen = '127.0.0.1',
) {

    # packages
    ensure_packages('nodejs')

    # paths
    $phabdir = "${basedir}/phabricator/"
    $aphlict_dir = "${phabdir}/support/aphlict/server"
    $node_modules = "${aphlict_dir}/node_modules"
    $aphlict_conf = "${basedir}/aphlict/config.json"
    $aphlict_start_cmd = "${phabdir}bin/aphlict start --config ${aphlict_conf}"
    $aphlict_stop_cmd = "${phabdir}bin/aphlict stop --config ${aphlict_conf}"

    # Ordering
    Package['nodejs'] -> File[$aphlict_conf] ~> Service['aphlict']
    File['/var/run/aphlict/'] -> File['/var/log/aphlict/'] -> Service['aphlict']
    User[$user] -> Service['aphlict']
    File[$node_modules] ~> Service['aphlict']

    if $ensure == 'present' {
        $service_ensure = 'running'
    } else {
        $service_ensure = 'stopped'
    }


    # Defines
    file { $node_modules:
        ensure => 'link',
        target => "${basedir}/aphlict/node_modules",
    }

    file { $aphlict_conf:
        ensure  => $ensure,
        content => template('phabricator/aphlict-config.json.erb'),
        owner   => $user,
        group   => $group,
        mode    => '0644',
    }

    file { '/var/run/aphlict/':
        ensure => 'directory',
        owner  => $user,
        group  => $group,
    }

    file { '/var/log/aphlict/':
        ensure => 'directory',
        owner  => $user,
        group  => $group,
    }

    logrotate::conf { 'aphlict':
        ensure  => $ensure,
        source  => 'puppet:///modules/phabricator/logrotate_aphlict',
        require => File['/var/log/aphlict/'],
    }

    # accounts
    group { $group:
        ensure => 'present',
        system => true,
    }

    user { $user:
        gid     => $group,
        shell   => '/bin/false',
        home    => '/var/run/aphlict',
        system  => true,
        require => Group[$group],
    }

    systemd::service { 'aphlict':
        ensure         => $ensure,
        content        => systemd_template('aphlict'),
        require        => User[$user],
        service_params => {
            hasrestart => false,
        },
    }

    profile::auto_restarts::service { 'aphlict':
        ensure => $ensure,
    }
}
