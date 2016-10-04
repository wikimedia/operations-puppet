# == Class: phabricator::aphlict
# Aphlict is the phabricator real-time notification relay service.
# Docs: https://secure.phabricator.com/book/phabricator/article/notifications/
class phabricator::aphlict(
    $user   = 'aphlict',
    $group  = 'aphlict',
) {
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

    # Defines
    file { $node_modules:
        ensure => 'link',
        target => "${basedir}/aphlict/node_modules",
    }

    file { $aphlict_conf:
        ensure  => 'present',
        content => template('phabricator/aphlict-config.json.erb'),
        owner   => $user,
        group   => $group,
        mode    => '0644',
    }

    if $::initsystem == 'upstart' {
        # upstart init conf file
        $init_file = '/etc/init/aphlict.conf'
        $init_source = 'aphlict-upstart.conf.erb'
    } else {
        # systemd service unit
        $init_file = '/etc/systemd/system/aphlict.service'
        $init_source = 'aphlict.service.erb'
    }

    file { '/etc/init.d/aphlict':
        ensure => 'link',
        target => "${phabdir}/bin/aphlict",
    }

    file { $init_file:
        content => template("phabricator/${init_source}"),
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
    }

    service { 'aphlict':
        ensure     => running,
        provider   => $::initsystem,
        hasrestart => true,
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
        ensure  => 'present',
        source  => 'puppet:///modules/phabricator/logrotate_aphlict',
        require => File['/var/log/aphlict/']
    }

    # accounts
    group { $group:
        ensure => 'present',
        system => true,
    }

    user { $user:
        gid    => 'aphlict',
        shell  => '/bin/false',
        home   => '/var/run/aphlict',
        system => true,
    }

}
