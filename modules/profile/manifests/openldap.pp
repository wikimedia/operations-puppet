# openldap server
class profile::openldap (
    $hostname = lookup('profile::openldap::hostname'),
    $mirror_mode = lookup('profile::openldap::mirror_mode'),
    $backup = lookup('profile::openldap::backup'),
    $sync_pass = lookup('profile::openldap::sync_pass'),
    $master = lookup('profile::openldap::master'),
    $server_id = lookup('profile::openldap::server_id'),
    $hash_passwords = lookup('profile::openldap::hash_passwords'),
    $read_only = lookup('profile::openldap::read_only'),
    $certname = lookup('profile::openldap::certname'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::eqiad1::openstack_controllers'),
    Integer             $size_limit = lookup('profile::openldap::size_limit'),
){
    # Certificate needs to be readable by slapd
    acme_chief::cert { $certname:
        puppet_svc => 'slapd',
        key_group  => 'openldap',
    }

    $suffix = 'dc=wikimedia,dc=org'

    class { '::openldap':
        server_id      => $server_id,
        sync_pass      => $sync_pass,
        suffix         => $suffix,
        datadir        => '/var/lib/ldap/labs',
        ca             => '/etc/ssl/certs/ca-certificates.crt',
        certificate    => "/etc/acmecerts/${certname}/live/rsa-2048.chained.crt",
        key            => "/etc/acmecerts/${certname}/live/rsa-2048.key",
        extra_schemas  => ['dnsdomain2.schema', 'nova_sun.schema', 'openssh-ldap.schema',
                          'puppet.schema', 'sudo.schema', 'wmf-user.schema'],
        extra_indices  => 'openldap/main-indices.erb',
        extra_acls     => template('openldap/main-acls.erb'),
        mirrormode     => $mirror_mode,
        master         => $master,
        hash_passwords => $hash_passwords,
        read_only      => $read_only,
        size_limit     => $size_limit,
    }

    # Ldap services are used all over the place, including within
    # WMCS and on various prod hosts.
    ferm::service { 'ldap':
        proto  => 'tcp',
        port   => '(389 636)',
        srange => '($PRODUCTION_NETWORKS $LABS_NETWORKS)',
    }

    $monitoring_rw_desc = $read_only.bool2str('read-only', 'writable')
    monitoring::service { 'ldap':
        description   => "LDAP (${monitoring_rw_desc} server)",
        check_command => 'check_ldap!dc=wikimedia,dc=org',
        critical      => false,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/LDAP#Troubleshooting',
    }

    file { '/usr/local/sbin/restart_openldap':
        source => 'puppet:///modules/ldap/restart_openldap',
        mode   => '0554',
        owner  => 'root',
        group  => 'root',
    }

    $minutes = fqdn_rand(60, $title)
    systemd::timer::job { 'restart_slapd':
        ensure      => 'present',
        user        => 'root',
        description => 'Restart slapd when using more than 50% of memory',
        command     => '/usr/local/sbin/restart_openldap',
        interval    => {'start' => 'OnCalendar', 'interval' => "*-*-* *:0/${minutes}:00"},
    }

    # restart slapd if it uses more than 50% of memory (T130593)
    cron { 'restart_slapd':
        ensure => 'absent',
    }

    if $backup {
        backup::openldapset { 'openldap': }
    }
}
