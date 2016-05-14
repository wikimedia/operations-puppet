#  Production RT
class role::requesttracker::server {
    system::role { 'requesttracker::server': description => 'RT server' }

    include passwords::misc::rt
    include base::firewall

    class { '::requesttracker':
        apache_site => 'rt.wikimedia.org',
        dbhost      => 'm1-master.eqiad.wmnet',
        dbport      => '',
        dbuser      => $passwords::misc::rt::rt_mysql_user,
        dbpass      => $passwords::misc::rt::rt_mysql_pass,
    }

    class { 'exim4':
        variant => 'heavy',
        config  => template('exim/exim4.conf.rt.erb'),
        filter  => template('exim/system_filter.conf.erb'),
    }
    include exim4::ganglia

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

    if os_version('ubuntu <= precise') {

        letsencrypt::cert::integrated { 'rt':
            subjects   => 'rt.wikimedia.org',
            puppet_svc => 'apache2',
            system_svc => 'apache2',
        }

        $ssl_settings = ssl_ciphersuite('apache', 'compat', '365')

        ferm::service { 'rt-https':
            proto => 'tcp',
            port  => '443',
        }

        monitoring::service { 'https':
            description   => 'HTTPS',
            check_command => 'check_ssl_http!rt.wikimedia.org',
        }
    }
}

