# SPDX-License-Identifier: Apache-2.0
# Set up rsync server and base config
class profile::dumps::distribution::rsync(
    Hash $rsyncer_settings = lookup('profile::dumps::distribution::rsync_config'),
) {
    $user = $rsyncer_settings['dumps_user']
    $group = $rsyncer_settings['dumps_group']
    $deploygroup = $rsyncer_settings['dumps_deploygroup']
    $mntpoint = $rsyncer_settings['dumps_mntpoint']

    class {'::dumps::rsync::common':
        user  => $user,
        group => $group,
    }

    # This directory is where the Airflow tasks performing mediawiki legacy dumps
    # will be syncing their data files. When we are ready, this can be changed to
    # harmonise with /srv/dumps/ See #T389784 for details.
    file { '/srv/mediawiki-dumps-legacy':
        ensure => 'directory',
        owner  => 'dumpsgen',
        group  => 'dumpsgen',
        mode   => '0750',
    }

    # This password will be used to authenticate Airflow task pods running on
    # dse-k8s to publish the mediawiki-dumps-legacy data files. See #T390738
    $rsync_secrets_file = '/etc/rsync_mediawiki_dumps_legacy_password'
    file { $rsync_secrets_file:
        mode      => '0400',
        content   => secret('dumps/rsync_mediawiki_dumps_legacy_password'),
        show_diff => false,
        require   => File['/srv/mediawiki-dumps-legacy'],
    }

    # This additional rsync module will permit Airflow task pods running on
    # dse-k8s to publish the mediawiki-dumps-legacy data files. See #T389784
    # Note that the path is currently different from the current production path
    # while the system is in pre-production.
    rsync::server::module { 'mediawiki-dumps-legacy':
        path          => '/srv/mediawiki-dumps-legacy',
        read_only     => 'no',
        hosts_allow   => $network::constants::dse_kubepods_networks,
        auto_firewall => true,
        auth_users    => ['dumpsgen'],
        secrets_file  => $rsync_secrets_file,
        require       => File[$rsync_secrets_file],
    }

    class {'::vm::higher_min_free_kbytes':}

    profile::auto_restarts::service { 'rsync': }
}
