# SPDX-License-Identifier: Apache-2.0
class profile::puppetserver::wmcs (
    Stdlib::Unixpath $git_basedir = lookup('profile::puppetserver::git::basedir'),
){
    include profile::openstack::base::puppetmaster::enc_client
    class { 'profile::puppetserver':
        enc_path => $profile::openstack::base::puppetmaster::enc_client::enc_path,
    }
    # To ensure the server is restarted on unattended java upgrades
    profile::auto_restarts::service { 'puppetserver': }

    # to prevent java from being upgraded via unattended-upgrades
    # see also T377803 and T385553
    apt::unattendedupgrades::exclude { 'cloud-vps-puppetserver-openjdk':
        package => 'openjdk-',
        prefix  => true,
    }

    class { 'puppetserver::gitsync':
        base_dir => $git_basedir,
        # TODO: make git_user a param to puppetmaster::gitpuppet and use that here
        git_user => 'gitpuppet',
    }

    # validatecloudvpsfqdn will look up an instance certname in nova
    #  and make sure it's for an actual instance before signing
    file { '/usr/local/sbin/validatecloudvpsfqdn.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/puppetmaster/validatecloudvpsfqdn.py',
    }

    file_line { 'pgit_alias':
        ensure => present,
        path   => '/root/.bashrc',
        line   => 'alias git=pgit',
    }

    file { '/usr/local/sbin/validatelabsfqdn.py':
        ensure => 'absent',
    }
}
