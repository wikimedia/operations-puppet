#Both app and admin user are limited to the appropriate
#database based on the connecting host.
include passwords::mysql::phabricator
$mysql_adminuser = $passwords::mysql::phabricator::admin_user
$mysql_adminpass = $passwords::mysql::phabricator::admin_pass
$mysql_appuser = $passwords::mysql::phabricator::app_user
$mysql_apppass = $passwords::mysql::phabricator::app_pass

class role::phabricator::legalpad {

    system::role { 'role::phabricator::legalpad': description => 'Phabricator (Legalpad)' }

    $current_tag = 'fabT440'
    class { '::phabricator':
        git_tag          => $current_tag,
        lock_file        => '/var/run/phab_repo_lock',
        mysql_admin_user => $::mysql_adminuser,
        mysql_admin_pass => $::mysql_adminpass,
        auth_type        => 'sul',
        settings         => {
            'darkconsole.enabled'                => true,
            'phabricator.base-uri'               => 'https://legalpad.wikimedia.org',
            'mysql.user'                         => $::mysql_appuser,
            'mysql.pass'                         => $::mysql_apppass,
            'mysql.host'                         => 'm3-master.eqiad.wmnet',
            'storage.default-namespace'          => 'phlegal',
            'phpmailer.smtp-host'                => 'polonium.wikimedia.org',
            'metamta.default-address'            => 'noreply@legalpad.wikimedia.org',
            'metamta.domain'                     => 'legalpad.wikimedia.org',
        },
    }

    # no 443 needed, we are behind misc. varnish
    ferm::service { 'phablegal_http':
        proto => 'tcp',
        port  => '80',
    }
}

class role::phabricator::main {

    system::role { 'role::phabricator::main': description => 'Phabricator (Main)' }

    $current_tag = 'fabT440'
    $domain = 'phabricator.wikimedia.org'
    class { '::phabricator':
        git_tag   => $current_tag,
        lock_file => '/var/run/phab_repo_lock',
        mysql_admin_user => $::mysql_adminuser,
        mysql_admin_pass => $::mysql_adminpass,
        auth_type => 'dual',
        settings  => {
            'storage.upload-size-limit'              => '10M',
            'darkconsole.enabled'                    => false,
            'phabricator.base-uri'                   => "https://${domain}",
            'mysql.user'                             => $::mysql_appuser,
            'mysql.pass'                             => $::mysql_apppass,
            'mysql.host'                             => 'm3-master.eqiad.wmnet',
            'phpmailer.smtp-host'                    => 'polonium.wikimedia.org',
            'metamta.default-address'                => "noreply@${domain}",
            'metamta.domain'                         => "${domain}",
            'metamta.maniphest.reply-handler-domain' => "${domain}",
            'metamta.maniphest.public-create-email'  => "task@${domain}",
            'metamta.reply-handler-domain'           => "${domain}",
        },
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

    #pass not sensitive but has to match phab and db
    $mysqlpass = 'labspass'
    $current_tag = 'fabT440'
    class { '::phabricator':
        git_tag   => $current_tag,
        lock_file => '/var/run/phab_repo_lock',
        auth_type => 'dual',
        settings  => {
            'darkconsole.enabled'                => true,
            'phabricator.base-uri'               => "http://${::hostname}.wmflabs.org",
            'phabricator.show-beta-applications' => true,
            'mysql.pass'                         => $mysqlpass,
            'auth.require-email-verification'    => false,
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
