# == Class: phabricator::aphlict
# Aphlict is the phabricator real-time notification relay service.
# Docs: https://secure.phabricator.com/book/phabricator/article/notifications/
class phabricator::aphlict(
    Wmflib::Ensure $ensure    = 'present',
    String $user              = 'aphlict',
    String $group             = 'aphlict',
    Stdlib::Unixpath $basedir = '/srv/phab'
) {

    # packages
    require_package('nodejs')

    # paths
    $phabdir = "${basedir}/phabricator/"
    $aphlict_dir = "${phabdir}/support/aphlict/server"
    $node_modules = "${aphlict_dir}/node_modules"
    $aphlict_conf = "${basedir}/aphlict/config.json"
    $aphlict_start_cmd = "${phabdir}bin/aphlict start --config ${aphlict_conf}"
    $aphlict_stop_cmd = "${phabdir}bin/aphlict stop --config ${aphlict_conf}"

    if $ensure == 'present' {
        # Ordering
        Package['nodejs'] -> File[$aphlict_conf] ~> Service['aphlict']
        File['/var/run/aphlict'] -> File['/var/log/aphlict'] -> Service['aphlict']
        User[$user] -> Service['aphlict']
        File[$node_modules] ~> Service['aphlict']

        $directory = 'directory'
        $service_ensure = 'running'
    } else {
        $directory = 'absent'
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

    file { '/var/run/aphlict':
        ensure => $directory,
        owner  => $user,
        group  => $group,
    }

    file { '/var/log/aphlict':
        ensure => $directory,
        owner  => $user,
        group  => $group,
    }

    logrotate::conf { 'aphlict':
        ensure  => $ensure,
        source  => 'puppet:///modules/phabricator/logrotate_aphlict',
        require => File['/var/log/aphlict'],
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

}
