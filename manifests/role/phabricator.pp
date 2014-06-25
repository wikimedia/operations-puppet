include passwords::mysql::phabricator
$mysql_adminuser = $passwords::mysql::phabricator::admin_user
$mysql_adminpass = $passwords::mysql::phabricator::admin_pass
$mysql_appuser = $passwords::mysql::phabricator::app_user
$mysql_apppass = $passwords::mysql::phabricator::app_pass

class role::phabricator::legalpad {

    $current_tag = 'fabT365'

    if $::realm == 'production' {

        system::role { 'role::phabricator::legalpad': description => 'Phabricator (Legalpad)' }

        class { '::phabricator':
            git_tag          => $current_tag,
            lock_file        => '/var/run/phab_repo_lock',
            mysql_admin_user => $mysql_adminuser,
            mysql_admin_pass => $mysql_adminpass,
            settings         => {
                'darkconsole.enabled'                => true,
                'phabricator.base-uri'               => 'https://legalpad.wikimedia.org',
                'phabricator.show-beta-applications' => true,
                'mysql.user'                         => $mysql_appuser,
                'mysql.pass'                         => $mysql_apppass,
                'mysql.host'                         => 'm3-master.eqiad.wmnet',
                'storage.default-namespace'          => 'phlegal',
                'metamta.mail-adapter'               => 'PhabricatorMailImplementationPHPMailerAdapter',
                'phpmailer.mailer'                   => 'smtp',
                'phpmailer.smtp-port'                => '25',
                'phpmailer.smtp-host'                => 'polonium.wikimedia.org',
                'auth.require-approval'              => false,
            },
        }
    }

    # firewalling, opens just port 80/tcp
    # no 443 needed, we are behind misc. varnish
    ferm::service { 'phablegal_http':
        proto => 'tcp',
        port  => '80',
    }

}



class role::phabricator::production {

    #This must exist git to be applicable
    $current_tag = 'rt7264'

    if $::realm == 'production' {

    system::role { 'role::phabricator::production': description => 'Phabricator (Production)' }

        class { '::phabricator':
            git_tag   => $current_tag,
            lock_file => '/var/run/phab_repo_lock',
            settings  => {
                'storage.upload-size-limit'          => '10M',
                'darkconsole.enabled'                => false,
                'phabricator.base-uri'               => 'https://phabricator.wikimedia.org',
                'metamta.mail-adapter'               => 'PhabricatorMailImplementationPHPMailerAdapter',
                'phpmailer.mailer'                   => 'smtp',
                'phpmailer.smtp-port'                => '25',
                'phpmailer.smtp-host'                => 'polonium.wikimedia.org',
                'storage.default-namespace'          => 'phprod',
                'mysql.user'                         => $mysql_appuser,
                'mysql.pass'                         => $mysql_apppass,
                'mysql.host'                         => 'm3-master.eqiad.wmnet',
                'phabricator.show-beta-applications' =>  true,
            },
        }
    }

    # firewalling, opens just port 80/tcp
    # no 443 needed, we are behind misc. varnish
    ferm::service { 'phabprod_http':
        proto => 'tcp',
        port  => '80',
    }

}
