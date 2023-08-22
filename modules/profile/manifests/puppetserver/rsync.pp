# SPDX-License-Identifier: Apache-2.0
# @summary Simple class to allow syncing of the volatile and CA directories
class profile::puppetserver::rsync {
    include profile::puppetserver
    include profile::puppetserver::volatile
    $volatile_dir = $profile::puppetserver::volatile::base_path
    $ca_dir       = $profile::puppetserver::ca_dir
    $ca_server    = $profile::puppetserver::ca_server
    $sync_ensure  = $profile::puppetserver::enable_ca.bool2str('absent', 'present')

    rsync::server::module {
        default:
            read_only   => 'yes',
            hosts_allow => wmflib::role::hosts('puppetserver'),
            chroot      => false;
        'puppet_volatile':
            path => $volatile_dir;
        'puppet_ca':
            path => $ca_dir;
    }

    systemd::timer::job { 'sync-puppet-volatile':
        ensure             => $sync_ensure,
        user               => 'root',
        description        => 'rsync puppet volatile data to another server',
        command            => "/usr/bin/rsync -avz --delete ${ca_server}::puppet_volatile ${volatile_dir}",
        interval           => {'start' => 'OnUnitInactiveSec', 'interval' => '15m'},
        monitoring_enabled => false,
        logging_enabled    => false,
    }

    systemd::timer::job { 'sync-puppet-ca':
        ensure             => $sync_ensure,
        user               => 'root',
        description        => 'rsync puppet CA data to another server',
        command            => "/usr/bin/rsync -avz --delete ${ca_server}::puppet_ca ${ca_dir}",
        interval           => {'start' => 'OnUnitInactiveSec', 'interval' => 'daily'},
        monitoring_enabled => false,
        logging_enabled    => false,
    }
    firewall::service { 'Rsync port to puppetservers':
        ensure => $sync_ensure,
        proto  => 'tcp',
        port   => [873],
        srange => wmflib::role::hosts('puppetserver') - $facts['networking']['fqdn'],
    }
}
