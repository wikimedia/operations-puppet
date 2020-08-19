# Class: otrs
#
# This class installs all the prerequisite packages for OTRS
#
# Parameters:
#   $otrs_database_host,
#       The MySQL OTRS database host
#   $otrs_database_name,
#       The MySQL OTRS database name
#   $otrs_database_user,
#       The MySQL OTRS database user
#   $otrs_database_pw,
#       The MySQL OTRS database pass
#   $otrs_daemon,
#       Whether to run the daemon. NOTE: only 1 daemon MUST run at time
#   $exim_database_name,
#       The MySQL OTRS database name (probably the same)
#   $exim_database_user,
#       The MySQL OTRS database user (probably not the same)
#   $exim_database_pass,
#       The MySQL OTRS database pass (probably not the same)
#   $trusted_networks,
#       The trusted by OTRS networks
#
# Actions:
#       Install OTRS and prerequisites
#
# Requires:
#
#  class {'::otrs':
#      otrs_database_host => 'host1',
#      otrs_database_name => 'otrs',
#      otrs_database_user => 'user',
#      otrs_database_pw   => 'pass',
#      otrs_daemon        => true,
#      exim_database_name => 'otrs',
#      exim_database_user => 'eximuser',
#      exim_database_pass => 'eximpass',
#      trusted_networks =>  [],
#  }
#
class otrs(
    Stdlib::Host $otrs_database_host,
    String $otrs_database_name,
    String $otrs_database_user,
    String $otrs_database_pw,
    Boolean $otrs_daemon,
    String $exim_database_name,
    String $exim_database_user,
    String $exim_database_pass,
    Array $trusted_networks,
) {
    # Implementation classes
    include ::otrs::web
    class { '::otrs::mail':
        otrs_mysql_database => $exim_database_name,
        otrs_mysql_user     => $exim_database_user,
        otrs_mysql_password => $exim_database_pass,
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
    require_package($packages)

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
        content => template('otrs/Config.pm.erb'),
    }

    file { '/opt/otrs/bin/otrs.TicketExport2Mbox.pl':
        ensure => 'file',
        owner  => 'otrs',
        group  => 'www-data',
        mode   => '0755',
        source => 'puppet:///modules/otrs/otrs.TicketExport2Mbox.pl',
    }

    file { '/opt/otrs/bin/cgi-bin/idle_agent_report':
        ensure => 'file',
        owner  => 'otrs',
        group  => 'www-data',
        mode   => '0755',
        source => 'puppet:///modules/otrs/idle_agent_report',
    }

    # WMF skin customizations
    file { '/opt/otrs/var/httpd/htdocs/skins/Agent/default/img/icons/product.ico':
        ensure => 'file',
        owner  => 'otrs',
        group  => 'www-data',
        mode   => '0664',
        source => 'puppet:///modules/otrs/wmf.ico',
    }
    file { '/opt/otrs/var/httpd/htdocs/skins/Agent/default/img/logo_bg_wmf.png':
        ensure => 'file',
        owner  => 'otrs',
        group  => 'www-data',
        mode   => '0664',
        source => 'puppet:///modules/otrs/logo_bg_wmf.png',
    }
    file { '/opt/otrs/var/httpd/htdocs/skins/Agent/default/img/loginlogo_wmf.png':
        ensure => 'file',
        owner  => 'otrs',
        group  => 'www-data',
        mode   => '0664',
        source => 'puppet:///modules/otrs/loginlogo_wmf.png',
    }

    $daemon_ensure = $otrs_daemon ? {
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

    cron { 'otrs-cache-cleanup':
        ensure  => 'present',
        user    => 'otrs',
        minute  => '50',
        hour    => '*',
        command => '/opt/otrs/bin/otrs.Console.pl Maint::Cache::Delete >/dev/null 2>&1',
    }
}
