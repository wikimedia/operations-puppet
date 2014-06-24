class varnish::htcppurger($varnish_instances=['localhost:80']) {
    Class[varnish::packages] -> Class[varnish::htcppurger]

    package { 'vhtcpd':
        ensure => latest,
    }

    file { '/etc/default/vhtcpd':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['vhtcpd'], # if we go first, we get overwritten
        # TODO: -r ^upload\\.wikimedia\\.org\$ (POSIX ERE, new param for class, quoting/escaping will be tricky...)
        content => inline_template('DAEMON_OPTS="-m 239.128.0.112<% varnish_instances.each do |inst| -%> -c <%= inst %><% end -%>"'),
    }

    # Wikimedia used to provide vhtcpd under the name varnishhtcpd with an
    # upstart job. This is nore more needed since the init script is provided
    # by vhtcpd package and the daemon got renamed vhtcpd.
    file { '/etc/init/varnishhtcpd.conf':
      ensure => absent,
    }

    service { 'vhtcpd':
        ensure     => running,
        require    => Package['vhtcpd'],
        subscribe  => File['/etc/default/vhtcpd'],
        hasstatus  => true,
        hasrestart => true,
    }

    nrpe::monitor_service { 'vhtcpd':
        description  => 'Varnish HTCP daemon',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u vhtcpd -a vhtcpd',
    }
}
