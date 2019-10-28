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

    cron { 'labs-ip-alias-dump':
        ensure  => 'present',
        user    => 'labsaliaser',
        command => 'if ! `/usr/local/bin/labs-ip-alias-dump.py --check-changes-only`; then /usr/local/bin/labs-ip-alias-dump.py; /usr/bin/rec_control reload-lua-script; fi  > /dev/null 2>&1',
        minute  => 30,
        require => File[
            '/usr/local/bin/labs-ip-alias-dump.py',
            '/etc/labs-dns-alias.yaml'
        ],
    }
}
