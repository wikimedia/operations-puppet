# SPDX-License-Identifier: Apache-2.0
# == Class profile::dns::auth::update::scripts
# Scripts used by the authdns-update system
#
class profile::dns::auth::update::scripts {
    # These are needed by gen-zones.py in the ops/dns repo, which
    # authdns-local-update will indirectly execute
    ensure_packages('python3-git')
    ensure_packages('python3-jinja2')

    # And this is needed by 'authdns-update' itself
    ensure_packages('clustershell')

    file { '/usr/local/sbin/authdns-update':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/profile/dns/auth/authdns-update',
    }

    file { '/usr/local/sbin/authdns-local-update':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/profile/dns/auth/authdns-local-update',
    }

    file { '/usr/local/sbin/authdns-git-pull':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/profile/dns/auth/authdns-git-pull',
    }
}
