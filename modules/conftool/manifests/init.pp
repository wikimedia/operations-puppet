# == Class conftool
#
# Installs conftool, and creates a wrapper script that can be run in git as
# a post-receive hook.

class conftool(
    $sync_dir_root = '/var/lib/operations/puppet/conftool-data',
    $config_file   = 'puppet:///modules/conftool/production.config.yaml',
    $ssl_dir       = '/var/lib/puppet',
    $use_ssl       = true,
    ) {
    require_package 'python-conftool'

    file { '/usr/local/bin/conftool-merge':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0500',
        content => template('conftool/conftool-merge.erb')
    }

    file { '/etc/conftool':
        ensure => directory,
        owner  => root,
        group  => root,
        mode   => '0755',
    }

    file { '/etc/conftool/config.yaml':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => '0444',
        source => $config_file,
        before => File['/usr/local/bin/conftool-merge'],
    }

    if $use_ssl {
        file { '/etc/conftool/ca.pem':
            ensure => present,
            owner  => root,
            group  => root,
            mode   => '0444',
            source => "${ssl_dir}/certs/ca.pem",
            before => File['/usr/local/bin/conftool-merge'],
        }
    }
}
