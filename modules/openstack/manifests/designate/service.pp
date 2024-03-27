# Designate provides DNSaaS services for OpenStack
# https://wiki.openstack.org/wiki/Designate

class openstack::designate::service(
    $active,
    $version,
    Array[Stdlib::Fqdn] $designate_hosts,
    Stdlib::Fqdn $keystone_fqdn,
    $db_user,
    $db_pass,
    $db_host,
    $db_name,
    $domain_id_internal_forward,
    $domain_id_internal_forward_legacy,
    $domain_id_internal_reverse,
    $puppetmaster_hostname,
    Array[Stdlib::Fqdn] $memcached_nodes,
    $ldap_user_pass,
    $pdns_api_key,
    $db_admin_user,
    $db_admin_pass,
    $pdns_hosts,
    Array[Stdlib::Fqdn] $rabbitmq_nodes,
    String[1] $rabbit_user,
    String[1] $rabbit_pass,
    $region,
    Boolean $enforce_policy_scope,
    Boolean $enforce_new_policy_defaults,
    ) {

    $designate_host_ips = $designate_hosts.map |$host| { ipresolve($host, 4) }

    # this sets 127.0.0.1 as fallback resolution, to avoid some rare chicken-egg problems
    # in which this resolution requires a working Designate but this is the puppet code
    # to set up Designate.
    $puppetmaster_hostname_ip = dnsquery::a($puppetmaster_hostname) || { ['127.0.0.1'] }[0]

    class { "openstack::designate::service::${version}": }

    file { '/usr/lib/python3/dist-packages/wmf_sink':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => "puppet:///modules/openstack/${version}/designate/wmf_sink",
        recurse => true,
        notify  => Service['designate-sink'],
    }

    file { '/usr/lib/python3/dist-packages/wmf_sink.egg-info':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => "puppet:///modules/openstack/${version}/designate/wmf_sink.egg-info",
        recurse => true,
        notify  => Service['designate-sink'],
    }

    file { '/usr/lib/python3/dist-packages/nova_fixed_multi':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => "puppet:///modules/openstack/${version}/designate/nova_fixed_multi",
        recurse => true,
        notify  => Service['designate-sink'],
    }

    file { '/usr/lib/python3/dist-packages/nova_fixed_multi.egg-info':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => "puppet:///modules/openstack/${version}/designate/nova_fixed_multi.egg-info",
        recurse => true,
        notify  => Service['designate-sink'],
    }

    file { '/usr/lib/python3/dist-packages/wmfdesignatelib.py':
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => "puppet:///modules/openstack/${version}/designate/wmfdesignatelib.py",
        notify => Service['designate-sink'],
    }

    # Stage pools.yaml.  Updating this file won't change active config;
    #  for that a user will need to manually run
    #
    #  $ sudo designate-manage pool update
    #
    file { '/etc/designate/pools.yaml':
        owner     => 'designate',
        group     => 'designate',
        mode      => '0440',
        show_diff => false,
        content   => template("openstack/${version}/designate/pools.yaml.erb"),
        require   => Package['designate-common'];
    }

    $keystone_auth_username = 'novaadmin'
    $keystone_auth_project = 'admin'
    file {
        '/etc/designate/designate.conf':
            owner     => 'designate',
            group     => 'designate',
            mode      => '0440',
            show_diff => false,
            content   => template("openstack/${version}/designate/designate.conf.erb"),
            notify    => Service[
              'designate-api',
              'designate-sink',
              'designate-central',
              'designate-mdns',
              'designate-producer',
              'designate-worker'],
            require   => Package['designate-common'];
        '/etc/designate/api-paste.ini':
            content => template("openstack/${version}/designate/api-paste.ini.erb"),
            owner   => 'designate',
            group   => 'designate',
            notify  => Service['designate-api','designate-sink','designate-central'],
            require => Package['designate-api'],
            mode    => '0440';
        '/etc/designate/policy.yaml':
            source  => "puppet:///modules/openstack/${version}/designate/policy.yaml",
            owner   => 'designate',
            group   => 'designate',
            notify  => Service['designate-api','designate-sink','designate-central'],
            require => Package['designate-common'],
            mode    => '0440';
        '/etc/designate/rootwrap.conf':
            source  => "puppet:///modules/openstack/${version}/designate/rootwrap.conf",
            owner   => 'root',
            group   => 'root',
            notify  => Service['designate-api','designate-sink','designate-central'],
            require => Package['designate-common'],
            mode    => '0440';
    }

    # Designate logrotate configurations were messed up for a long time
    # late Liberty versions fix this but this logrotate setup here should
    # ensure consistent state (T186142).
    logrotate::conf { 'designate-common':
        ensure => 'present',
        source => 'puppet:///modules/openstack/designate/designate-common.logrotate',
    }

    file { '/var/lib/designate/.ssh/':
        ensure => 'directory',
        owner  => 'designate',
        group  => 'designate',
    }

    file { '/var/lib/designate/.ssh/id_rsa':
        owner     => 'designate',
        group     => 'designate',
        mode      => '0400',
        content   => secret('ssh/puppet_cert_manager/cert_manager'),
        show_diff => false,
    }

    # include rootwrap.d entries

    service {'designate-api':
        ensure  => $active,
        require => Package['designate-api'];
    }

    service {'designate-sink':
        ensure  => $active,
        require => Package['designate-sink'];
    }

    service {'designate-central':
        ensure  => $active,
        require => Package['designate-central'];
    }

    service {'designate-mdns':
        ensure  => $active,
        require =>  [
            Package['designate'],
        ],
    }

    service {'designate-pool-manager':
        ensure  => stopped,
    }

    service {'designate-zone-manager':
        ensure  => stopped,
    }

    $systemd_ensure = $active ? {
        true => 'present',
        default => 'absent',
    }

    # The Newton designate packages don't include service defs for
    #  the -worker or -producer services.  Hopefully we can replace these
    #  with simple service defines in O.
    systemd::service { 'designate-producer':
        ensure  => $systemd_ensure,
        content => systemd_template('designate-producer'),
        restart => true,
        require =>  [
            Package['designate'],
        ],
    }

    systemd::service { 'designate-worker':
        ensure  => $systemd_ensure,
        content => systemd_template('designate-worker'),
        restart => true,
        require =>  [
            Package['designate'],
        ],
    }

    file { '/var/lib/designate/.ssh/instance-puppet-user.priv':
        ensure => absent,
    }

    rsyslog::conf { 'designate':
        source   => 'puppet:///modules/openstack/designate/designate.rsyslog.conf',
        priority => 20,
    }
}
