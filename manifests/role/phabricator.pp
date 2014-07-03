$current_tag = 'fabT365'
include passwords::mysql::phabricator
$mysql_adminuser = $passwords::mysql::phabricator::admin_user
$mysql_adminpass = $passwords::mysql::phabricator::admin_pass
$mysql_appuser = $passwords::mysql::phabricator::app_user
$mysql_apppass = $passwords::mysql::phabricator::app_pass

class role::phabricator::legalpad {

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
                'phpmailer.smtp-port'                => "25",
                'phpmailer.smtp-host'                => 'polonium.wikimedia.org',
                'auth.require-approval'              => false,
            },
        }
    }
}
