# == Class authdns::monitoring
# Scripts used by the authdns system. These used to be in a package,
# but we don't do that anymore and provisioning them here instead.
#
class authdns::scripts {
    if ! defined(Package['python-jinja2']){
        package { 'python-jinja2':
            ensure => present,
        }
    }

    file { '/usr/local/bin/authdns-gen-zones':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => "puppet:///modules/${module_name}/authdns-gen-zones.py",
    }

    file { '/usr/local/bin/authdns-lint':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => "puppet:///modules/${module_name}/authdns-lint",
    }

    file { '/usr/local/sbin/authdns-update':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => "puppet:///modules/${module_name}/authdns-update",
    }

    file { '/usr/local/sbin/authdns-local-update':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => "puppet:///modules/${module_name}/authdns-local-update",
    }

    file { '/usr/local/sbin/authdns-git-pull':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => "puppet:///modules/${module_name}/authdns-git-pull",
    }
}
