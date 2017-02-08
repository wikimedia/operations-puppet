# == Class: zotero
#
# Zotero is a service based on running the Zotero Firefox extension via xpcshell
# and JavaScript wrappers. It is meant to scrape URLs provided to it and return
# metadata.
#
# === Parameters
#
# [*http_proxy*]
#   HTTP proxy, in "host:port" format. Optional.
#
class zotero( $http_proxy = undef ) {

    include ::service::configuration

    if $http_proxy =~ /:/ {
        $http_proxy_port = regsubst($http_proxy, '.*:', '')
        $http_proxy_host = regsubst($http_proxy, ':.*', '')
    } else {
        $http_proxy_port = undef
        $http_proxy_host = undef
    }

    $log_dir = "${::service::configuration::log_dir}/zotero"

    package { 'xulrunner-dev':
        ensure => present,
        before => Service['zotero'],
    }

    package { 'firejail':
        ensure => present,
        before => Service['zotero'],
    }

    scap::target { 'zotero/translators':
        deploy_user  => 'deploy-service',
        service_name => 'zotero',
        before       => Service['zotero'],
    }

    scap::target { 'zotero/translation-server':
        deploy_user  => 'deploy-service',
        service_name => 'zotero',
        before       => Service['zotero'],
    }

    # /srv/deployment/zotero/translation-server/defaults/preferences/defaults.js
    # should be symlinked to this file
    file { '/etc/zotero':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
    file { '/etc/zotero/defaults.js':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('zotero/defaults.js.erb'),
        require => Scap::Target['zotero/translation-server'],
        notify  => Service['zotero'],
    }

    group { 'zotero':
        ensure => present,
        system => true,
    }

    user { 'zotero':
        gid    => 'zotero',
        home   => '/nonexistent',
        shell  => '/bin/false',
        system => true,
    }

    file { $log_dir:
        ensure => directory,
        owner  => 'zotero',
        group  => 'zotero',
        mode   => '0755',
        before => Service['zotero'],
    }

    file { '/etc/logrotate.d/zotero':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('zotero/logrotate.erb'),
        before  => Service['zotero'],
    }

    file { '/etc/init/zotero.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('zotero/upstart.erb'),
        notify  => Service['zotero'],
    }

    file { '/etc/ld.so.conf.d/zotero.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('zotero/ldso.erb'),
    }

    exec { 'zotero-run-ldconfig':
        subscribe   => File['/etc/ld.so.conf.d/zotero.conf'],
        command     => '/sbin/ldconfig',
        refreshonly => true,
        notify      => Service['zotero'],
    }

    file { '/etc/cron.d/zotero-restart':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/zotero/cron.file',
        require => Service['zotero'],
    }

    service { 'zotero':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        provider   => 'upstart',
    }
}
