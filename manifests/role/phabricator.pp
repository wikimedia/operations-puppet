class role::phabricator::config {
    #Both app and admin user are limited to the appropriate
    #database based on the connecting host.
    include passwords::mysql::phabricator
    $mysql_adminuser = $passwords::mysql::phabricator::admin_user
    $mysql_adminpass = $passwords::mysql::phabricator::admin_pass
    $mysql_appuser = $passwords::mysql::phabricator::app_user
    $mysql_apppass = $passwords::mysql::phabricator::app_pass
    $mysql_maniphestuser = $passwords::mysql::phabricator::manifest_user
    $mysql_maniphestpass = $passwords::mysql::phabricator::manifest_pass
}

# production phabricator instance
class role::phabricator::main {
    include role::phabricator::config

    system::role { 'role::phabricator::main':
        description => 'Phabricator (Main)'
    }

    #let's go jenkins
    $current_tag = 'release/2015-01-08/1'
    $domain = 'phabricator.wikimedia.org'
    $altdom = 'phab.wmfusercontent.org'
    $mysql_host = 'm3-master.eqiad.wmnet'

    class { '::phabricator':
        git_tag          => $current_tag,
        lock_file        => '/var/run/phab_repo_lock',
        mysql_admin_user => $role::phabricator::config::mysql_adminuser,
        mysql_admin_pass => $role::phabricator::config::mysql_adminpass,
        auth_type        => 'dual',
        sprint_tag       => 'release/2015-01-08/1',
        security_tag     => 'release/2015-01-13/1',
        libraries        => ['/srv/phab/libext/Sprint/src',
                             '/srv/phab/libext/security/src'],
        extension_tag    => 'HEAD',
        extensions       => [ 'MediaWikiUserpageCustomField.php',
                              'LDAPUserpageCustomField.php'],
        settings         => {
            'storage.upload-size-limit'                 => '10M',
            'darkconsole.enabled'                       => false,
            'phabricator.base-uri'                      => "https://${domain}",
            'security.alternate-file-domain'            => "https://${altdom}",
            'mysql.user'                                => $role::phabricator::config::mysql_appuser,
            'mysql.pass'                                => $role::phabricator::config::mysql_apppass,
            'mysql.host'                                => $mysql_host,
            'phpmailer.smtp-host'                       => inline_template('<%= @mail_smarthost.join(";") %>'),
            'metamta.default-address'                   => "no-reply@${domain}",
            'metamta.domain'                            => $domain,
            'metamta.maniphest.reply-handler-domain'    => $domain,
            'metamta.maniphest.public-create-email'     => "task@${domain}",
            'metamta.reply-handler-domain'              => $domain,
            'repository.default-local-path'             => '/srv/phab/repos',
            'phd.start-taskmasters'                     => 10,
            'events.listeners'                          => ['SecurityPolicyEventListener'],
        },
    }

    class { 'exim::roled':
        local_domains           => [ '+system_domains', '+phab_domains' ],
        enable_mail_relay       => false,
        enable_external_mail    => false,
        smart_route_list        => $::mail_smarthost,
        enable_mailman          => false,
        phab_relay              => true,
        enable_spamassassin     => false,
    }

    include passwords::phabricator
    $emailbotcert = $passwords::phabricator::emailbot_cert

    include phabricator::monitoring

    class { '::phabricator::mailrelay':
        default          => {
            security     => 'users',
            maint        => false,
            taskcreation => "task@${domain}",
        },
        address_routing => {
            ulsfo    => 'ops-ulsfo',
            codfw    => 'ops-codfw',
            pmtpa    => 'ops-pmtpa',
            esams    => 'ops-esams',
            eqiad    => 'ops-eqiad',
            network  => 'ops-network',
            ops-requests => 'operations',
            testproj     => 'demoproject'
        },
# Enabling direct email to task for on-site queues per T87454
        direct_comments_allowed => {
            ops-codfw => '*',
            ops-eqiad => '*',
            ops-esams => '*',
            ops-ulsfo => '*',
        },
        phab_bot        => {
            root_dir    => '/srv/phab/phabricator/',
            username    => 'emailbot',
            host        => "https://${domain}/api/",
            certificate => $emailbotcert,
        },
    }

    ferm::service { 'phabmain_http':
        proto    => 'tcp',
        port     => '80',
    }

    ferm::service { 'phabmain_https':
        proto    => 'tcp',
        port     => '443',
    }

    # receive mail from mail smarthosts
    ferm::service { 'phabmain-smtp':
        port     => '25',
        proto    => 'tcp',
        srange   => inline_template('(<%= @mail_smarthost.map{|x| "@resolve(#{x})" }.join(" ") %>)'),
    }

    # redirect bugzilla URL patterns to phabricator
    # handles translation of bug numbers to maniphest task ids
    phabricator::redirector { "redirector.${domain}":
        mysql_user    => $role::phabricator::config::mysql_maniphestuser,
        mysql_pass    => $role::phabricator::config::mysql_maniphestpass,
        mysql_host    => $mysql_host,
        rootdir       => '/srv/phab',
        field_index   => '4rRUkCdImLQU',
        phab_host     => $domain,
        alt_host      => $altdom,
    }

    # community metrics mail (RT #3962, T1003)
    phabricator::logmail {'communitymetrics':
        script_name  => 'community_metrics.sh',
        rcpt_address => 'communitymetrics@wikimedia.org',
        sndr_address => 'communitymetrics@wikimedia.org',
        monthday     => '1',
    }
}

# phabricator instance on wmflabs at phab-0[1-9].wmflabs.org
class role::phabricator::labs {

    # pass not sensitive but has to match phab and db
    $mysqlpass = 'labspass'
    $current_tag = 'release/2015-01-08/1'
    class { '::phabricator':
        git_tag          => $current_tag,
        lock_file        => '/var/run/phab_repo_lock',
        auth_type        => 'local',
        sprint_tag       => 'release/2015-01-08/1',
        libraries        => {
              'sprint'   => '/srv/phab/libext/Sprint/src',
        },
        extension_tag    => 'HEAD',
        extensions       => [ 'MediaWikiUserpageCustomField.php',
                              'LDAPUserpageCustomField.php'],
        settings         => {
            'darkconsole.enabled'             => true,
            'phabricator.base-uri'            => "https://${::hostname}.wmflabs.org",
            'mysql.pass'                      => $mysqlpass,
            'auth.require-email-verification' => false,
            'metamta.mail-adapter'            => 'PhabricatorMailImplementationTestAdapter',
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

    # dummy redirector to test out the redirect patterns for bugzilla
    phabricator::redirector { 'redirector.fab-01.wmflabs.org':
        mysql_user    => 'root',
        mysql_pass    => $mysqlpass,
        mysql_host    => 'localhost',
        rootdir       => '/srv/phab',
        field_index   => 'yERhvoZPNPtM',
        phab_host     => 'phab-01.wmflabs.org',
        alt_host      => 'phab-01.wmflabs.org',
    }
}
