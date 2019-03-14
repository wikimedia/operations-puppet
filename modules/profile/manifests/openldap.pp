# openldap server
class profile::openldap (
    $hostname = hiera('profile::openldap::hostname'),
    $mirror_mode = hiera('profile::openldap::mirror_mode'),
    $backup = hiera('profile::openldap::backup'),
    $sync_pass = hiera('profile::openldap::sync_pass'),
    $master = hiera('profile::openldap::master', undef),
    $server_id = hiera('profile::openldap::server_id'),
    $hash_passwords = hiera('profile::openldap::hash_passwords'),
    $read_only = hiera('profile::openldap::read_only'),
    $certname = hiera('profile::openldap::certname'),
){
    # Certificate needs to be readable by slapd
    acme_chief::cert { $certname:
        puppet_svc => 'slapd',
    }

    class { '::openldap':
        server_id      => $server_id,
        sync_pass      => $sync_pass,
        suffix         => 'dc=wikimedia,dc=org',
        datadir        => '/var/lib/ldap/labs',
        ca             => '/etc/ssl/certs/ca-certificates.crt',
        certificate    => "/etc/acmecerts/${certname}.rsa-2048.crt",
        key            => "/etc/acmecerts/${certname}.rsa-2048.key",
        extra_schemas  => ['dnsdomain2.schema', 'nova_sun.schema', 'openssh-ldap.schema',
                          'puppet.schema', 'sudo.schema'],
        extra_indices  => 'openldap/labs-indices.erb',
        extra_acls     => 'openldap/labs-acls.erb',
        mirrormode     => $mirror_mode,
        master         => $master,
        hash_passwords => $hash_passwords,
        read_only      => $read_only,
    }

    # Ldap services are used all over the place, including within
    #  labs and on various prod hosts.
    ferm::service { 'labs_ldap':
        proto  => 'tcp',
        port   => '(389 636)',
        srange => '($PRODUCTION_NETWORKS $LABS_NETWORKS)',
    }

    monitoring::service { 'labs_ldap_check':
        description   => 'Labs LDAP ',
        check_command => 'check_ldap!dc=wikimedia,dc=org',
        critical      => false,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/LDAP#Troubleshooting',
    }

    # restart slapd if it uses more than 50% of memory (T130593)
    cron { 'restart_slapd':
        ensure  => present,
        minute  => fqdn_rand(60, $title),
        command => "/bin/ps -C slapd -o pmem= | awk '{sum+=\$1} END { if (sum <= 50.0) exit 1 }' \
        && /bin/systemctl restart slapd >/dev/null 2>/dev/null",
    }

    if $backup {
        backup::openldapset {'openldap_labs':}
    }
}
