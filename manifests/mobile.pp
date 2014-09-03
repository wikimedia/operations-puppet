# This file is for mobile classes
class mobile::vumi::iptables-purges {
    require 'iptables::tables'

    # The deny_all rule must always be purged,
    #otherwise ACCEPTs can be placed below it
    iptables_purge_service{ 'deny_all_redis':
        service => 'redis',
    }

    # When removing or modifying a rule,
    #place the old rule here, otherwise it won't
    # be purged, and will stay in the iptables forever
}

class mobile::vumi::iptables-accepts {
    require 'mobile::vumi::iptables-purges'

    # Rememeber to place modified or removed rules into purges!
    iptables_add_service{ 'redis_internal':
        source  => '208.80.152.0/22',
        service => 'redis',
        jump    => 'ACCEPT',
    }
}

class mobile::vumi::iptables-drops {
    require 'mobile::vumi::iptables-accepts'

    # Deny by default
    iptables_add_service{ 'deny_all_redis':
        service => 'redis',
        jump    => 'DROP',
    }
}

class mobile::vumi::iptables  {
    if $::realm == 'production' {
        # We use the following requirement chain:
        # iptables -> iptables::drops -> iptables::accepts -> iptables::accept-established -> iptables::purges
        # This ensures proper ordering of the rules
        require 'mobile::vumi::iptables-drops'

        # This exec should always occur last in the requirement chain.
        iptables_add_exec{ $::hostname:
            service => 'vumi',
        }
    }

    # Labs has security groups, and as such, doesn't need firewall rules
}

class mobile::vumi {

    include passwords::mobile::vumi,
        mobile::vumi::iptables,
        ::redis::client::python

    $testvumi_pw          = $passwords::mobile::vumi::wikipedia_xmpp_sms_out
    $vumi_pw              = $passwords::mobile::vumi::wikipedia_xmpp
    $tata_sms_incoming_pw = $passwords::mobile::vumi::tata_sms_incoming_pw
    $tata_sms_outgoing_pw = $passwords::mobile::vumi::tata_sms_outgoing_pw
    $tata_ussd_pw         = $passwords::mobile::vumi::tata_ussd_pw
    $tata_hyd_ussd_pw     = $passwords::mobile::vumi::tata_hyd_ussd_pw

    file { '/a':
        ensure => 'directory',
    }

    class { 'redis':
        maxmemory => '1024Mb',
    }
    include redis::ganglia
    package { 'python-iso8601':
        ensure => '0.1.4-1ubuntu1',
    }

    package { 'python-smpp':
        ensure => '0.1-0~ppa3',
    }

    package { 'python-ssmi':
        ensure => '0.0.4-1~ppa3',
    }

    package { 'python-txamqp':
        ensure => '0.6.1-1~ppa3',
    }

    package { 'vumi':
        ensure => '0.5.0~a+143-0~ppa3',
    }

    package { 'vumi-wikipedia':
        ensure => '0.1~a+14-0~ppa3',
    }

    package { 'python-twisted':
        ensure => 'latest',
    }

    package { 'python-tz':
        ensure => 'latest',
    }

    package { 'python-wokkel':
        ensure => '0.7.0-1',
    }

    package { 'rabbitmq-server':
        ensure => 'latest',
    }

    package { 'supervisor':
        ensure => 'latest',
    }

    service { 'supervisor':
        ensure  => 'running',
        enable  => true,
        require => Package['supervisor'],
    }

    file { '/etc/vumi':
        ensure => 'directory',
        owner  => 'root',
    }

    file { '/var/log/vumi':
        ensure => 'directory',
        owner  => 'root',
    }

    file { '/etc/vumi/wikipedia.yaml':
        owner   => 'root',
        source  => 'puppet:///files/mobile/vumi/wikipedia.yaml',
        require => File['/etc/vumi'],
        mode    => '0444',
    }

    file { '/etc/vumi/tata_ussd_dispatcher.yaml':
        owner   => 'root',
        source  => 'puppet:///files/mobile/vumi/tata_ussd_dispatcher.yaml',
        require => File['/etc/vumi'],
        mode    => '0444',
    }

    file { '/etc/vumi/tata_ussd_hyd.yaml':
        owner   => 'root',
        content => template('mobile/vumi/tata_ussd_hyd.yaml.erb'),
        require => File['/etc/vumi'],
        mode    => '0444',
    }

    file { '/etc/vumi/tata_sms_outgoing.yaml':
        owner   => 'root',
        content => template('mobile/vumi/tata_sms_outgoing.yaml.erb'),
        require => File['/etc/vumi'],
        mode    => '0444',
    }

    file { '/etc/vumi/tata_ussd_delhi.yaml':
        owner   => 'root',
        content => template('mobile/vumi/tata_ussd_delhi.yaml.erb'),
        require => File['/etc/vumi'],
        mode    => '0444',
    }

    file { '/etc/vumi/tata_sms_incoming.yaml':
        owner   => 'root',
        content => template('mobile/vumi/tata_sms_incoming.yaml.erb'),
        require => File['/etc/vumi'],
        mode    => '0444',
    }

    file { '/etc/supervisor/conf.d/supervisord.wikipedia.conf':
        owner   => 'root',
        source  => 'puppet:///files/mobile/vumi/supervisord.wikipedia.conf',
        require => Package['supervisor'],
        mode    => '0444',
    }

    file { '/etc/vumi/wikipedia_xmpp.yaml':
        owner   => 'root',
        content => template('mobile/vumi/wikipedia_xmpp.yaml.erb'),
        require => File['/etc/vumi'],
        mode    => '0444',
    }

    file { '/etc/vumi/wikipedia_xmpp_sms.yaml':
        owner   => 'root',
        content => template('mobile/vumi/wikipedia_xmpp_sms.yaml.erb'),
        require => File['/etc/vumi'],
        mode    => '0444',
    }

    file { '/usr/local/vumi':
        ensure => 'directory',
        owner  => 'root',
    }

    file { '/usr/local/vumi/rabbitmq.setup.sh':
        owner   => 'root',
        mode    => '0555',
        require => File['/usr/local/vumi'],
        source  => 'puppet:///files/mobile/vumi/rabbitmq.setup.sh',
    }

    exec { 'Set permissions for rabbitmq user':
        command => '/usr/local/vumi/rabbitmq.setup.sh',
        user    => 'root',
        require => File['/usr/local/vumi/rabbitmq.setup.sh'],
        unless  => '/usr/sbin/rabbitmqctl list_user_permissions vumi | grep develop',
    }
}

class mobile::vumi::udp2log {
    class { 'misc::udp2log':
        monitor => false,
    }

    file { '/var/log/vumi/metrics.log':
        ensure => 'present',
        owner  => 'root',
        group  => 'udp2log',
        mode   => '0664',
    }

    # oxygen's udp2log instance
    # saves logs mainly in /a/squid
    misc::udp2log::instance { 'vumi':
        port                => '5678',
    # 1KB is the smallest passable receive queue for vumi
    # so logs are flushed more often
        recv_queue          => '1',
        monitor_packet_loss => false,
        monitor_log_age     => false,
        require             => [File['/var/log/vumi'],
                                File['/var/log/vumi/metrics.log']
        ],
    }
}
