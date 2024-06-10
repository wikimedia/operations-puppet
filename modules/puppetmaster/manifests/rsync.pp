# === Class puppetmaster::rsync
#
# Simple class to allow syncing of the volatile and CA directories
#
class puppetmaster::rsync(
    String $server,
    Wmflib::Ensure $sync_ensure = 'absent',
    Array[String] $frontends = [],
){

    rsync::server::module {
        default:
            read_only   => 'yes',
            hosts_allow => $frontends,
            chroot      => false;
        'puppet_volatile':
            path => '/var/lib/puppet/volatile';
        'puppet_ca':
            path => '/var/lib/puppet/server/ssl/ca';
    }

    systemd::timer::job { 'sync-puppet-volatile':
        ensure             => $sync_ensure,
        user               => 'root',
        description        => 'rsync puppet volatile data to another server',
        command            => "/usr/bin/rsync -avz --delete ${server}::puppet_volatile /var/lib/puppet/volatile",
        interval           => {'start' => 'OnUnitInactiveSec', 'interval' => '15m'},
        logging_enabled    => true,
        monitoring_enabled => true,
        timeout_start_sec  => 300,
    }

    systemd::timer::job { 'sync-puppet-ca':
        ensure             => $sync_ensure,
        user               => 'root',
        description        => 'rsync puppet CA data to another server',
        command            => "/usr/bin/rsync -avz --delete ${server}::puppet_ca /var/lib/puppet/server/ssl/ca",
        interval           => {'start' => 'OnUnitInactiveSec', 'interval' => 'daily'},
        logging_enabled    => true,
        monitoring_enabled => true,
        timeout_start_sec  => 300,
    }
}
