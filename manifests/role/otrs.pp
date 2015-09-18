# vim: set ts=4 et sw=4:               =>
# role/otrs.pp

class role::otrs (
        $otrs_database_host = 'm2-master.eqiad.wmnet',
        $otrs_database_name = 'otrs',
    ) {

    system::role { 'role::otrs::webserver':
        description => 'OTRS Web Application Server',
    }
    include standard
    include ::otrs

    include passwords::mysql::otrs

    $otrs_database_user = $::passwords::mysql::otrs::user
    $otrs_database_pw   = $::passwords::mysql::otrs::pass


    ferm::service { 'otrs_http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'otrs_https':
        proto => 'tcp',
        port  => '443',
    }

    ferm::service { 'otrs_smtp':
        proto  => 'tcp',
        port   => '25',
        srange => '($EXTERNAL_NETWORKS)',
    }

    monitoring::service { 'smtp':
        description   => 'OTRS SMTP',
        check_command => 'check_smtp',
    }

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => 'check_ssl_http!ticket.wikimedia.org',
    }

    # can conflict with ferm module
    if ! defined(Package['libnet-dns-perl']){
        package { 'libnet-dns-perl':
            ensure => present,
        }
    }
}
