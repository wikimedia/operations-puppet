# SPDX-License-Identifier: Apache-2.0
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
    String $install_version,
    Stdlib::Host $vrts_database_host,
    Stdlib::Host $active_host,
    Stdlib::Host $passive_host,
    String $vrts_database_name,
    String $vrts_database_user,
    String $vrts_database_pw,
    String $vrts_database_port,
    Boolean $vrts_daemon,
    String $exim_database_name,
    String $exim_database_user,
    String $exim_database_pass,
    Array $trusted_networks,
    String $download_url,
    String $http_proxy,
    String $https_proxy,
    String $public_dns,
    Array[Stdlib::Fqdn] $mail_smarthosts,
) {
    # Implementation Classes
    class { '::vrts::web':
        domain_name => $public_dns,
    }

    class { '::vrts::mail':
        vrts_mysql_database => $exim_database_name,
        vrts_mysql_user     => $exim_database_user,
        vrts_mysql_password => $exim_database_pass,
        trusted_networks    => $trusted_networks,
        mail_smarthosts     => $mail_smarthosts,
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
        'libxml-libxml-perl',
        'libxml-libxslt-perl',
        'libencode-hanextra-perl',

        # Added in 6.3.4 as required
        'libauthen-sasl-perl',
        'libmail-imapclient-perl',

        # Added in 6.4.5 as required
        'libical-parser-perl',

        'default-mysql-client',

    ]
    ensure_packages($packages)

    package { 'libdatetime-timezone-perl': ensure => latest }

    user { 'otrs':
        home       => '/var/lib/otrs',
        groups     => 'www-data',
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
    }

    wmflib::dir::mkdir_p('/etc/vrts', {
        owner => 'root',
        group => 'root',
        mode  => '0755',
    })

    # Maintenance Scripts
    file {
        default:
            ensure => file,
            owner  => 'root',
            group  => 'root',
            mode   => '0744';
        '/etc/vrts/install-script-vars':
            content => template('vrts/install-script-vars.erb');
        '/usr/local/bin/install_vrts':
            require => File['/etc/vrts/install-script-vars'],
            source  => 'puppet:///modules/vrts/install_vrts.sh';
        '/usr/local/bin/upgrade_vrts':
            source  => 'puppet:///modules/vrts/upgrade_vrts.sh';
    }

    exec { 'Fresh Install':
        path    => '/usr/local/bin',
        command => "/usr/local/bin/install_vrts ${install_version}",
        unless  => 'test -L /opt/otrs',
        require => File['/usr/local/bin/install_vrts'],
    }

    # Configs
    file {
        default:
            ensure => file,
            owner  => 'otrs',
            mode   => '0755',
            group  => 'www-data';
        '/opt/otrs/Kernel/Config.pm':
            mode    => '0440',
            content => template('vrts/Config.pm.erb');
        '/opt/otrs/bin/otrs.TicketExport2Mbox.pl':
            source => 'puppet:///modules/vrts/vrts.TicketExport2Mbox.pl';
        '/opt/otrs/scripts/apache2-perl-startup.pl':
            source => 'puppet:///modules/vrts/apache2-perl-startup.pl';
    }

    # WMF Skin Customizations
    file {
        default:
            ensure => file,
            owner  => 'otrs',
            group  => 'www-data',
            mode   => '0664';
        '/opt/otrs/var/httpd/htdocs/skins/Agent/default/img/icons/product.ico':
            source => 'puppet:///modules/vrts/wmf.ico';
        '/opt/otrs/var/httpd/htdocs/skins/Agent/default/img/logo_bg_wmf.png':
            source => 'puppet:///modules/vrts/logo_bg_wmf.png';
        '/opt/otrs/var/httpd/htdocs/skins/Agent/default/img/loginlogo_wmf.png':
            source => 'puppet:///modules/vrts/loginlogo_wmf.png';
    }

    $daemon_ensure = $vrts_daemon ? {
        true    => present,
        default => absent,
    }

    systemd::service { 'vrts-daemon':
        ensure         => $daemon_ensure,
        content        => systemd_template('vrts-daemon'),
        restart        => true,
        service_params => {
            hasstatus  => true,
            hasrestart => false,
        },
    }

    systemd::timer::job { 'vrts-cache-cleanup':
        ensure      => absent,
        user        => 'otrs',
        description => 'Cleanup VRTS cache',
        command     => '/opt/otrs/bin/otrs.Console.pl Maint::Cache::Delete',
        interval    => {'start' => 'OnCalendar', 'interval' => 'hourly'},
    }

    rsync::quickdatacopy { 'vrts':
        ensure              => present,
        source_host         => $active_host,
        dest_host           => $passive_host,
        auto_sync           => false,
        module_path         => '/opt',
        server_uses_stunnel => true,
        progress            => true,
    }
}
