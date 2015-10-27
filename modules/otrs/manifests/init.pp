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
#      otrs_database_pw =>  'pass
#      exim_database_name => 'otrs',
#      exim_database_user => 'eximuser',
#      exim_database_pass => 'eximpass',
#      trusted_networks =>  [],
#  }
#
class otrs(
    $otrs_database_host,
    $otrs_database_name,
    $otrs_database_user,
    $otrs_database_pw,
    $exim_database_name,
    $exim_database_user,
    $exim_database_pass,
    $trusted_networks,
) {
    # Implementation classes
    include otrs::web
    class { 'otrs::mail':
        otrs_mysql_database => $exim_database_name,
        otrs_mysql_user     => $exim_database_user,
        otrs_mysql_password => $exim_database_pass,
        trusted_networks    => $trusted_networks,
    }

    # Installation
    $packages = [
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
        'mysql-client',
        'perl-doc',
    ]

    package { $packages:
        ensure => 'present',
    }

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

    # TODO: Remove this after the migration to 5.0.x is complete
    file { '/etc/cron.d/otrs':
        ensure => absent,
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

    file { '/opt/otrs/var/httpd/htdocs/skins/Agent/default/img/icons/product.ico':
        ensure => 'file',
        owner  => 'otrs',
        group  => 'www-data',
        mode   => '0664',
        source => 'puppet:///modules/otrs/wmf.ico',
    }

    file { '/opt/otrs/Kernel/Output/HTML/OTRS':
        ensure => link,
        target => '/opt/otrs/Kernel/Output/HTML/Standard',
    }

    # TODO: Remove the safeguard once we are jessie only
    # NOTE: We couple the move to 4.0.x OTRS with the move to jessie, since that
    # should not bite back as after the move the 3.2.x install we have will be
    # decomissioned
    if os_version('debian >= jessie') {
        base::service_unit { 'otrs-daemon':
            ensure  => present,
            upstart => false,
            systemd => true,
            refresh => true,
            service_params => {
                enable     => true,
                hasstatus  => true,
                hasrestart => false,
            }
        }
    }
}
