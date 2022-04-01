# Class: vrts
#
# This class installs all the prerequisite packages for VRTS
#
# Parameters:
#   $vrts_database_host,
#       The MySQL VRTS database host
#   $vrts_database_name,
#       The MySQL VRTS database name
#   $vrts_database_user,
#       The MySQL VRTS database user
#   $vrts_database_pw,
#       The MySQL VRTS database pass
#   $vrts_daemon,
#       Whether to run the daemon. NOTE: only 1 daemon MUST run at time
#   $exim_database_name,
#       The MySQL VRTS database name (probably the same)
#   $exim_database_user,
#       The MySQL VRTS database user (probably not the same)
#   $exim_database_pass,
#       The MySQL VRTS database pass (probably not the same)
#   $trusted_networks,
#       The trusted by VRTS networks
#
# Actions:
#       Install VRTS and prerequisites
#
# Requires:
#
#  class {'::vrts':
#      vrts_database_host => 'host1',
#      vrts_database_name => 'otrs',
#      vrts_database_user => 'user',
#      vrts_database_pw   => 'pass',
#      vrts_daemon        => true,
#      exim_database_name => 'otrs',
#      exim_database_user => 'eximuser',
#      exim_database_pass => 'eximpass',
#      trusted_networks =>  [],
#  }
#
class vrts(
    Stdlib::Host $vrts_database_host,
    String $vrts_database_name,
    String $vrts_database_user,
    String $vrts_database_pw,
    Boolean $vrts_daemon,
    String $exim_database_name,
    String $exim_database_user,
    String $exim_database_pass,
    Array $trusted_networks,
) {
    # Implementation classes
    include ::vrts::web
    class { '::vrts::mail':
        vrts_mysql_database => $exim_database_name,
        vrts_mysql_user     => $exim_database_user,
        vrts_mysql_password => $exim_database_pass,
        trusted_networks    => $trusted_networks,
    }

    # Installation
    $packages = [
        'libapache2-mod-perl2',
        'libapache-dbi-perl',
        'libdbd-mysql-perl',
        'libgd-graph-perl',
        'libgd-text-perl',
        'libio-socket-ssl-perl',
        'libjson-xs-perl',
        'libnet-ldap-perl',
        'libpdf-api2-perl',
        'libsoap-lite-perl',
        'libtext-csv-xs-perl',
        'libtimedate-perl',
        'libyaml-libyaml-perl',
        'libtemplate-perl',
        'libarchive-zip-perl',

        # T248814. Added in 5.0.42 as prereqs
        'libmoo-perl',
        'libnamespace-clean-perl',

        'perl-doc',
        # T187984. Added in 6.0.x as prereqs and optionals
        'libdatetime-perl',
        'libdatetime-timezone-perl',
        'libxml-libxml-perl',
        'libxml-libxslt-perl',
        'libencode-hanextra-perl',

        'default-mysql-client',

    ]
    ensure_packages($packages)

    user { 'otrs':
        home       => '/var/lib/otrs',
        groups     => 'www-data',
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
    }

    file { '/opt/otrs/Kernel/Config.pm':
        ensure  => 'file',
        owner   => 'otrs',
        group   => 'www-data',
        mode    => '0440',
        content => template('vrts/Config.pm.erb'),
    }

    file { '/opt/otrs/bin/otrs.TicketExport2Mbox.pl':
        ensure => 'file',
        owner  => 'otrs',
        group  => 'www-data',
        mode   => '0755',
        source => 'puppet:///modules/vrts/otrs.TicketExport2Mbox.pl',
    }

    file { '/opt/otrs/bin/cgi-bin/idle_agent_report':
        ensure => 'file',
        owner  => 'otrs',
        group  => 'www-data',
        mode   => '0755',
        source => 'puppet:///modules/vrts/idle_agent_report',
    }

    # WMF skin customizations
    file { '/opt/otrs/var/httpd/htdocs/skins/Agent/default/img/icons/product.ico':
        ensure => 'file',
        owner  => 'otrs',
        group  => 'www-data',
        mode   => '0664',
        source => 'puppet:///modules/vrts/wmf.ico',
    }
    file { '/opt/otrs/var/httpd/htdocs/skins/Agent/default/img/logo_bg_wmf.png':
        ensure => 'file',
        owner  => 'otrs',
        group  => 'www-data',
        mode   => '0664',
        source => 'puppet:///modules/vrts/logo_bg_wmf.png',
    }
    file { '/opt/otrs/var/httpd/htdocs/skins/Agent/default/img/loginlogo_wmf.png':
        ensure => 'file',
        owner  => 'otrs',
        group  => 'www-data',
        mode   => '0664',
        source => 'puppet:///modules/vrts/loginlogo_wmf.png',
    }

    $daemon_ensure = $vrts_daemon ? {
        true    => present,
        default => absent,
    }
    systemd::service { 'otrs-daemon':
        ensure         => $daemon_ensure,
        content        => systemd_template('otrs-daemon'),
        restart        => true,
        service_params => {
            hasstatus  => true,
            hasrestart => false,
        },
    }

    systemd::timer::job { 'otrs-cache-cleanup':
        ensure      => 'present',
        user        => 'otrs',
        description => 'Cleanup OTRS cache',
        command     => '/opt/otrs/bin/otrs.Console.pl Maint::Cache::Delete',
        interval    => {'start' => 'OnCalendar', 'interval' => 'hourly'},
    }

}
