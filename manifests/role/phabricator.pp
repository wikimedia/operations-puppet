#Both app and admin user are limited to the appropriate
#database based on the connecting host.
include passwords::mysql::phabricator
$mysql_adminuser = $passwords::mysql::phabricator::admin_user
$mysql_adminpass = $passwords::mysql::phabricator::admin_pass
$mysql_appuser = $passwords::mysql::phabricator::app_user
$mysql_apppass = $passwords::mysql::phabricator::app_pass

class role::phabricator::legalpad {

    $current_tag = 'fabT440'
    if $::realm == 'production' {

        system::role { 'role::phabricator::legalpad': description => 'Phabricator (Legalpad)' }

        class { '::phabricator':
            git_tag          => $current_tag,
            lock_file        => '/var/run/phab_repo_lock',
            mysql_admin_user => $::mysql_adminuser,
            mysql_admin_pass => $::mysql_adminpass,
            settings         => {
                'darkconsole.enabled'                => true,
                'phabricator.base-uri'               => 'https://legalpad.wikimedia.org',
                'phabricator.show-beta-applications' => true,
                'mysql.user'                         => $::mysql_appuser,
                'mysql.pass'                         => $::mysql_apppass,
                'mysql.host'                         => 'm3-master.eqiad.wmnet',
                'storage.default-namespace'          => 'phlegal',
                'metamta.mail-adapter'               => 'PhabricatorMailImplementationPHPMailerAdapter',
                'phpmailer.mailer'                   => 'smtp',
                'phpmailer.smtp-port'                => '25',
                'phpmailer.smtp-host'                => 'polonium.wikimedia.org',
                'auth.require-approval'              => false,
                'auth.require-email-verification'    => true,
                'metamta.default-address'            => 'noreply@legalpad.wikimedia.org',
                'metamta.domain'                     => 'legalpad.wikimedia.org',
            },
        }
    }
    # no 443 needed, we are behind misc. varnish
    ferm::service { 'phablegal_http':
        proto => 'tcp',
        port  => '80',
    }
}

class role::phabricator::main {

    $current_tag = 'fabT440'
    if $::realm == 'production' {

    system::role { 'role::phabricator::main': description => 'Phabricator (Main)' }

        class { '::phabricator':
            git_tag   => $current_tag,
            lock_file => '/var/run/phab_repo_lock',
            settings  => {
                'storage.upload-size-limit'          => '10M',
                'darkconsole.enabled'                => false,
                'phabricator.base-uri'               => 'http://phabricator.wikimedia.org',
                'metamta.mail-adapter'               => 'PhabricatorMailImplementationPHPMailerAdapter',
                'phpmailer.mailer'                   => 'smtp',
                'phpmailer.smtp-port'                => '25',
                'phpmailer.smtp-host'                => 'polonium.wikimedia.org',
                'mysql.user'                         => $::mysql_appuser,
                'mysql.pass'                         => $::mysql_apppass,
                'mysql.host'                         => 'm3-master.eqiad.wmnet',
                'phabricator.show-beta-applications' =>  true,
            },
        }
    }

    class { 'exim::roled':
        local_domains          => [ '+system_domains', '+phab_domains' ],
        enable_mail_relay      => false,
        enable_external_mail   => false,
        smart_route_list       => $::mail_smarthost,
        enable_mailman         => false,
        phab_relay             => true,
        enable_mail_submission => false,
        enable_spamassassin    => false,
    }


    ferm::service { 'phabmain_http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'phabmain_https':
        proto => 'tcp',
        port  => '443',
    }

    # receive mail from mail smarthosts
    ferm::service { 'phabmain-smtp':
        port   => '25',
        proto  => 'tcp',
        srange => inline_template('(<%= @mail_smarthost.map{|x| "@resolve(#{x})" }.join(" ") %>)'),
    }
}


class role::phabricator::labs {

    $current_tag = 'fabT440'
    #not sensitive but has to match phab and db
    $mysqlpass = 'labspass'
    class { '::phabricator':
        git_tag   => $current_tag,
        lock_file => '/var/run/phab_repo_lock',
        settings  => {
            'darkconsole.enabled'                => true,
            'phabricator.base-uri'               => "http://${::hostname}.wmflabs.org",
            'phabricator.show-beta-applications' => true,
            'mysql.pass'                         => $mysqlpass,
        },
    }

    package { 'mysql-server': ensure => present }

    class { 'mysql::config':
        root_password => $mysqlpass,
        sql_mode      => 'STRICT_ALL_TABLES',
        restart       => true,
        require       => Package['mysql-server'],
    }

    service { 'mysql':
        ensure     => running,
        hasrestart => true,
        hasstatus  => true,
        require    => Package['mysql-server'],
    }
}
