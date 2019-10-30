# == class: dnsrecursor::labsaliaser
#
# Provision a script and cron job to setup private IP space answers for dns
# lookups that resolve to public ips and add other misc records.
class dnsrecursor::labsaliaser(
    $username,
    $password,
    $nova_api_url,
    $extra_records,
    $observer_project_name,
) {
    user { 'labsaliaser':
        ensure => present,
        system => true,
        home   => '/nonexistent',
        shell  => '/bin/false',
    }
    file { '/var/cache/labsaliaser':
        ensure  => directory,
        owner   => 'labsaliaser',
        group   => 'labsaliaser',
        mode    => '0644',
        require => User['labsaliaser'],
    }

    $config = {
        'username'              => $username,
        'password'              => $password,
        'output_path'           => '/var/cache/labsaliaser/labs-ip-aliases.json',
        'nova_api_url'          => $nova_api_url,
        'extra_records'         => $extra_records,
        'observer_project_name' => $observer_project_name,
    }

    file { '/etc/labs-dns-alias.yaml':
        ensure  => present,
        owner   => 'labsaliaser',
        group   => 'labsaliaser',
        mode    => '0440',
        content => ordered_yaml($config),
    }

    package { 'lua-json':
        ensure => present,
    }

    file { '/usr/local/bin/labs-ip-alias-dump.py':
        ensure  => present,
        owner   => 'labsaliaser',
        group   => 'labsaliaser',
        mode    => '0550',
        source  => 'puppet:///modules/dnsrecursor/labs-ip-alias-dump.py',
        require => [
            Package['lua-json'],
            File['/var/cache/labsaliaser'],
        ],
    }

    file { '/usr/local/bin/labsalias-dump.sh':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0500',
        source  => 'puppet:///modules/dnsrecursor/labsalias-dump.sh',
        require => [
            File['/usr/local/bin/labs-ip-alias-dump.py'],
        ],
    }

    # TODO: remove after the timer is established
    cron { 'labs-ip-alias-dump':
        ensure  => 'absent',
        user    => 'labsaliaser',
        command => 'if ! `/usr/local/bin/labs-ip-alias-dump.py --check-changes-only`; then /usr/local/bin/labs-ip-alias-dump.py; /usr/bin/rec_control reload-lua-script; fi  > /dev/null',
        minute  => 30,
    }

    systemd::timer::job { 'labs-ip-alias-dump':
        ensure          => 'present',
        # Don't log to file, use journald
        logging_enabled => false,
        user            => 'root',
        description     => 'Update the mapping that splits internal and external DNS for Cloud VPS instances',
        command         => '/usr/local/bin/labsalias-dump.sh',
        interval        => {
        'start'    => 'OnCalendar',
        'interval' => '*-*-* *:30:00', # hourly at half-past
        },
        require         => File[
            '/usr/local/bin/labsalias-dump.sh',
            '/etc/labs-dns-alias.yaml'
        ],
    }
}
