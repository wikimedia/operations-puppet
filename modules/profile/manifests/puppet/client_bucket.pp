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
    $script = @("SCRIPT"/L)
    #!/bin/bash
    if [ -z "$(/usr/bin/find /var/lib/puppet/clientbucket -type f -size +${max_size} | head -c1)" ]
    then
        printf "OK: client bucket file ok\n"
        exit 0
    fi
    printf "WARNING: large files in client bucket\n"
    exit 2
    | SCRIPT
    $check_name = 'check_client_bucket'
    $check_command = "/usr/local/lib/nagios/plugins/${check_name}"
    nrpe::plugin { $check_name:
        content => $script,
    }
    sudo::user { 'nrpe_check_client_bucket_large_file':
        ensure     => $ensure,
        user       => 'nagios',
        privileges => [ "ALL = NOPASSWD: ${check_command}"]
    }
    nrpe::monitor_service { 'client_bucket_large_file':
        ensure       => $ensure,
        description  => 'Check for large files in client bucket',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Puppet#check_client_bucket_large_file',
        nrpe_command => "/usr/bin/sudo -n ${check_command}",
    }
}
