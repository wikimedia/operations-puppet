# cleans up puppet client bucket (T165885)
class profile::puppet::clean_client_bucket(
    Wmflib::Ensure $ensure = lookup('profile::puppet::clean_client_bucket::ensure', {'default_value' => 'present'}),
    Integer $file_age = lookup('profile::puppet::file_age', {'default_value' => 14}),
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
}
