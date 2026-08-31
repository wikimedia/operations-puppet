# openldap server
class profile::openldap_clouddev (
    $hostname = lookup('profile::openldap::hostname'),
    $mirror_mode = lookup('profile::openldap::mirror_mode'),
    $backup = lookup('profile::openldap::backup'),
    $sync_pass = lookup('profile::openldap_clouddev::openldap::sync_pass'),
    $master = lookup('profile::openldap::master'),
    $server_id = lookup('profile::openldap::server_id'),
    $hash_passwords = lookup('profile::openldap::hash_passwords'),
    $read_only = lookup('profile::openldap::read_only'),
    $certname = lookup('profile::openldap::certname'),
    $storage_backend = lookup('profile::openldap::storage_backend'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::codfw1dev::openstack_control_nodes'),

){
    # Certificate needs to be readable by slapd
    acme_chief::cert { $certname:
        puppet_svc => 'slapd',
        key_group  => 'openldap',
    }

    $suffix = 'dc=wikimedia,dc=org'

    $epp_params = {
        'suffix'             => $suffix,
        'cloudcontrol_hosts' => $openstack_control_nodes.map |OpenStack::ControlNode $node| { $node['cloud_private_fqdn'] },
    }

    class { '::openldap':
        server_id       => $server_id,
        sync_pass       => $sync_pass,
        suffix          => $suffix,
        datadir         => '/var/lib/ldap/labs',
        ca              => '/etc/ssl/certs/ca-certificates.crt',
        certificate     => "/etc/acmecerts/${certname}/live/ec-prime256v1.chained.crt",
        key             => "/etc/acmecerts/${certname}/live/ec-prime256v1.key",
        extra_schemas   => ['dnsdomain2.schema', 'nova_sun.schema', 'openssh-ldap.schema',
                            'puppet.schema', 'sudo.schema', 'wmf-user.schema'],
        extra_indices   => 'openldap/main-indices.erb',
        extra_acls      => epp('openldap/main-acls.epp', $epp_params),
        mirrormode      => $mirror_mode,
        master          => $master,
        hash_passwords  => $hash_passwords,
        read_only       => $read_only,
        storage_backend => $storage_backend,
    }

    # Ldap services are used all over the place, including within
    # WMCS and on various prod hosts.
    firewall::service { 'ldap':
        proto    => 'tcp',
        port     => [389, 636],
        src_sets => ['PRODUCTION_NETWORKS', 'CLOUD_NETWORKS'],
    }

    if $backup {
        backup::openldapset { 'openldap': }
    }

    include profile::openldap::restarts
}
