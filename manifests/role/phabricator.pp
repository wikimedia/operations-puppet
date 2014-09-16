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
            'darkconsole.enabled'                => false,
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

    $current_tag = 'phT172'
    $domain = 'phabricator.wikimedia.org'
    class { '::phabricator':
        git_tag          => $current_tag,
        lock_file        => '/var/run/phab_repo_lock',
        mysql_admin_user => $::mysql_adminuser,
        mysql_admin_pass => $::mysql_adminpass,
        auth_type        => 'dual',
        extension_tag    => 'HEAD',
        extensions       => ['MediaWikiUserpageCustomField.php',
                             'SecurityPolicyEnforcerAction.php'],
        settings         => {
            'search.elastic.host'                    => 'http://search.svc.eqiad.wmnet:9200',
            'search.elastic.namespace'               => 'phabricatormain',
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

    include passwords::phabricator
    $emailbotcert = $passwords::phabricator::emailbot_cert

    class { '::phabricator::mailrelay':
        default                   => { security => 'default'},
        address_routing           => { testproj => 'demoproject'},
        phab_bot                  => { root_dir    => '/srv/phab/phabricator/',
                                       env         => 'default',
                                       username    => 'emailbot',
                                       host        => "http://${domain}",
                                       certificate => $emailbotcert,
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
    $current_tag = 'phT172'
    class { '::phabricator':
        git_tag          => $current_tag,
        lock_file        => '/var/run/phab_repo_lock',
        auth_type        => 'local',
        extension_tag    => 'HEAD',
        extensions       => ['SecurityPolicyEnforcerAction.php'],
        settings         => {
            'search.elastic.host'                => 'http://localhost:9200',
            'search.elastic.namespace'           => 'phabricator',
            'darkconsole.enabled'                => true,
            'phabricator.base-uri'               => "https://${::hostname}.wmflabs.org",
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
    package { 'openjdk-7-jre-headless':
        ensure => present,
    }

    package { 'elasticsearch':
        ensure     => present,
        require    => Package['openjdk-7-jre-headless'],
    }

    service { 'elasticsearch':
        ensure     => running,
        hasrestart => true,
        hasstatus  => true,
        require    => Package['elasticsearch'],
    }
}
