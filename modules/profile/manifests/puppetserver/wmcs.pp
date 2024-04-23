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

    class { 'puppetmaster::gitsync':
        base_dir => $git_basedir,
        # TODO: make git_user a param to puppetmaster::gitpuppet and use that here
        git_user => 'gitpuppet',
    }

    # validatelabsfqdn will look up an instance certname in nova
    #  and make sure it's for an actual instance before signing
    file { '/usr/local/sbin/validatelabsfqdn.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/puppetmaster/validatelabsfqdn.py',
    }
}
