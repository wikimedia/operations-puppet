class role::phabricator {

    $current_tag = 'rt7264'
    include passwords::mysql::phabricator
    $mysql_adminuser = $passwords::mysql::phabricator::admin_user
    $mysql_adminpass = $passwords::mysql::phabricator::admin_pass
    $mysql_appuser = $passwords::mysql::phabricator::app_user
    $mysql_apppass = $passwords::mysql::phabricator::app_pass

    if $::realm == 'production' {

        #designated to iridium can be below it soon
        if ($::fqdn =~ /^radon.eqiad.wmnet/) {
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
                },
            }
        }
    }
}
