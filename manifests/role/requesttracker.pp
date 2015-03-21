#  Production RT
class role::requesttracker {
    system::role { 'requesttracker': description => 'RT' }

    include passwords::misc::rt

    install_certificate { 'rt.wikimedia.org': }

    $ssl_settings = ssl_ciphersuite('apache-2.2', 'compat', '7')

    class { '::requesttracker':
        apache_site => 'rt.wikimedia.org',
        dbhost      => 'm1-master.eqiad.wmnet',
        dbport      => '',
        dbuser      => $passwords::misc::rt::rt_mysql_user,
        dbpass      => $passwords::misc::rt::rt_mysql_pass,
    }

    class { 'exim::roled':
        local_domains        => [ '+system_domains', '+rt_domains' ],
        enable_mail_relay    => false,
        enable_external_mail => false,
        smart_route_list     => $::mail_smarthost,
        enable_mailman       => false,
        rt_relay             => true,
        enable_spamassassin  => false,
    }

    # allow RT to receive mail from mail smarthosts
    ferm::service { 'rt-smtp':
        port   => '25',
        proto  => 'tcp',
        srange => inline_template('(<%= @mail_smarthost.map{|x| "@resolve(#{x})" }.join(" ") %>)'),

    }

    ferm::service { 'rt-http':
        proto => 'tcp',
        port  => '80',
    }
    ferm::service { 'rt-https':
        proto => 'tcp',
        port  => '443',
    }

    monitoring::service { 'RT-https':
        description   => 'RT-HTTPS',
        check_command => 'check_https_url!rt.wikimedia.org!/',
    }

}

#  Labs/testing RT
class role::rt::labs {
    system::role { 'role::rt::labs': description => 'RT (Labs)' }

    include passwords::misc::rt

    # FIXME: needs to reference a wmflabs certificate?
    install_certificate { 'rt.wikimedia.org': }

    $datadir = '/srv/mysql'

    class { '::requesttracker':
        apache_site => $::fqdn,
        dbuser      => $passwords::misc::rt::rt_mysql_user,
        dbpass      => $passwords::misc::rt::rt_mysql_pass,
        datadir     => $datadir,
    }

    class { 'mysql::server':
        config_hash => {
            'datadir' => $datadir,
        }
    }

    exec { 'rt-db-initialize':
        command => "/bin/echo '' | /usr/sbin/rt-setup-database --action init --dba root --prompt-for-dba-password",
        unless  => '/usr/bin/mysqlshow rt4',
        require => Class['::requesttracker', 'mysql::server'],
    }
}

