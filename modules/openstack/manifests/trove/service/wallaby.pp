class openstack::trove::service::wallaby(
    Array[Stdlib::Fqdn] $openstack_controllers,
    Integer             $workers,
    String              $db_user,
    String              $db_pass,
    String              $db_name,
    Stdlib::Fqdn        $db_host,
    String              $ldap_user_pass,
    String              $keystone_admin_uri,
    String              $keystone_internal_uri,
    String              $region,
    Stdlib::Port        $api_bind_port,
    String              $rabbit_user,
    String              $rabbit_pass,
    String              $trove_guest_rabbit_user,
    String              $trove_guest_rabbit_pass,
    String              $trove_service_user_pass,
    String              $trove_service_project,
    String              $trove_service_user,
    String              $trove_quay_user,
    String              $trove_quay_pass,
    String              $designate_internal_uri,
    String              $trove_dns_zone,
    String              $trove_dns_zone_id,
) {
    require "openstack::serverpackages::wallaby::${::lsbdistcodename}"

    package { ['python3-trove', 'trove-common', 'trove-api', 'trove-taskmanager', 'trove-conductor']:
        ensure => 'present',
    }

    file {
        '/etc/trove/trove.conf':
            content   => template('openstack/wallaby/trove/trove.conf.erb'),
            owner     => 'trove',
            group     => 'trove',
            mode      => '0440',
            show_diff => false,
            notify    => Service['trove-api', 'trove-taskmanager', 'trove-conductor'],
            require   => Package['trove-api'];
        '/etc/trove/trove-guestagent.conf':
            content   => template('openstack/wallaby/trove/trove-guestagent.conf.erb'),
            owner     => 'trove',
            group     => 'trove',
            mode      => '0440',
            show_diff => false,
            notify    => Service['trove-api', 'trove-taskmanager', 'trove-conductor'],
            require   => Package['trove-api'];
        '/etc/trove/policy.yaml':
            source  => 'puppet:///modules/openstack/wallaby/trove/policy.yaml',
            owner   => 'trove',
            group   => 'trove',
            mode    => '0644',
            notify  => Service['trove-api', 'trove-taskmanager', 'trove-conductor'],
            require => Package['trove-api'];
        '/etc/trove/api-paste.ini':
            source  => 'puppet:///modules/openstack/wallaby/trove/api-paste.ini',
            owner   => 'trove',
            group   => 'trove',
            mode    => '0644',
            notify  => Service['trove-api'],
            require => Package['trove-api'];
        # This file is not used as far as I know, but the bullseye/victoria package post-install
        #  fails if it is not present.
        '/usr/share/trove-common/api-paste.ini':
            source => 'puppet:///modules/openstack/wallaby/trove/api-paste.ini',
            owner  => 'trove',
            group  => 'trove',
            mode   => '0644';
        '/usr/lib/python3/dist-packages/trove/taskmanager/models.py':
            source  => 'puppet:///modules/openstack/wallaby/trove/hacks/taskmanager/models.py',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['trove-api'],
            require => Package['trove-api'];
        '/usr/lib/python3/dist-packages/trove/instance/models.py':
            source  => 'puppet:///modules/openstack/wallaby/trove/hacks/instance/models.py',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['trove-api'],
            require => Package['trove-api'];
    }
}
