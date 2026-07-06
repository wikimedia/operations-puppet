# SPDX-License-Identifier: Apache-2.0
class profile::puppetserver::wmcs (
    Array[Stdlib::HTTPUrl] $puppetdb_urls = lookup('profile::puppetserver::puppetdb_urls'),
    Stdlib::Unixpath       $git_basedir   = lookup('profile::puppetserver::git::basedir'),
) {
    include profile::openstack::base::puppetserver::enc_client

    class { 'profile::puppetserver':
        enc_path => $profile::openstack::base::puppetserver::enc_client::enc_path,
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
        # TODO: use $git_user from puppetserver::gitsync
        git_user => 'gitpuppet',
    }

    # validatecloudvpsfqdn will look up an instance certname in nova
    #  and make sure it's for an actual instance before signing
    file { '/usr/local/sbin/validatecloudvpsfqdn.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/puppetserver/validatecloudvpsfqdn.py',
    }

    file_line { 'pgit_alias':
        ensure => present,
        path   => '/root/.bashrc',
        line   => 'alias git=pgit',
    }

    # Prune old fact files generated in environments without puppetdb access (T417795)
    $minute = fqdn_rand(60, 'puppetserver-clean-stale-facts')
    systemd::timer::job { 'puppetserver-clean-stale-facts':
        ensure      => stdlib::ensure($puppetdb_urls.empty()),
        description => 'clean stale puppet fact files',
        user        => 'puppet',
        command     => '/usr/bin/find /var/lib/puppetserver/server_data/facts/ -type f -mtime +7 -delete',
        interval    => {'start' => 'OnCalendar', 'interval' => "*-*-* *:${minute}:0"},
        require     => Package['puppetserver'],
    }
}
