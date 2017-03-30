# == Class: phabricator::aphlict
# Aphlict is the phabricator real-time notification relay service.
# Docs: https://secure.phabricator.com/book/phabricator/article/notifications/
class phabricator::aphlict(
    $ensure = 'present',
    $user   = 'aphlict',
    $group  = 'aphlict',
) {
    validate_ensure($ensure)

    # packages
    require_package('nodejs')

    # paths
    $basedir = $phabricator::phabdir
    $phabdir = "${basedir}/phabricator/"
    $aphlict_dir = "${phabdir}/support/aphlict/server"
    $node_modules = "${aphlict_dir}/node_modules"
    $aphlict_conf = "${basedir}/aphlict/config.json"
    $aphlict_cmd = "${phabdir}/bin/aphlict start --config ${aphlict_conf}"

    # Ordering
    Package['nodejs'] -> File[$aphlict_conf] ~> Service['aphlict']
    File['/var/run/aphlict/'] -> File['/var/log/aphlict/'] -> Service['aphlict']
    User[$user] -> Service['aphlict']
    File[$node_modules] ~> Service['aphlict']

    if $ensure == 'present' {
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

    file { '/var/run/aphlict/':
        ensure => $directory,
        owner  => $user,
        group  => $group,
    }

    file { '/var/log/aphlict/':
        ensure => $directory,
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
        ensure => $ensure,
        system => true,
    }

    user { $user:
        gid    => $group,
        shell  => '/bin/false',
        home   => '/var/run/aphlict',
        system => true,
    }

    base::service_unit { 'aphlict':
        ensure         => $ensure,
        systemd        => true,
        upstart        => true,
        sysvinit       => false,
        require        => User[$user],
        service_params => {
            ensure     => $service_ensure,
            provider   => $::initsystem,
            hasrestart => false,
        },
    }

}
