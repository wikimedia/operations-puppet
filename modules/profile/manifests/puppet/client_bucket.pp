# cleans up puppet client bucket (T165885)
class profile::puppet::client_bucket(
    Wmflib::Ensure   $ensure   = lookup('profile::puppet::client_bucket::ensure'),
    Integer          $file_age = lookup('profile::puppet::client_bucket::file_age'),
    Stdlib::Datasize $max_size = lookup('profile::puppet::client_bucket::max_size'),
){

    systemd::timer::job { 'clean_puppet_client_bucket':
        ensure             => $ensure,
        description        => 'Delete old files from the puppet client bucket',
        command            => "/usr/bin/find /var/lib/puppet/clientbucket/ -type f -mtime +${file_age} -atime +${file_age} -delete",
        interval           => {
            'start'    => 'OnUnitInactiveSec',
            'interval' => '24h',
        },
        logging_enabled    => false,
        monitoring_enabled => false,
        user               => 'root',
    }
    $find_command = "/usr/bin/find /var/lib/puppet/clientbucket -type f -size +${max_size}"
    sudo::user { 'nrpe_check_client_bucket_large_file':
        ensure     => $ensure,
        user       => 'nagios',
        privileges => [ "ALL = NOPASSWD: ${find_command}"]
    }
    nrpe::monitor_service { 'check_client_bucket_large_file':
        ensure       => absent,  # TODO: fix once we fix the nrpe check
        description  => 'Check for large files in client bucket',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Puppet#check_client_bucket_large_file',
        nrpe_command => "/usr/bin/test -z \"$(/usr/bin/sudo ${find_command} | head -c1)\"",
    }
}
