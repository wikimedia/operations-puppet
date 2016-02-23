class role::phabricator::config {
    #Both app and admin user are limited to the appropriate
    #database based on the connecting host.
    include passwords::mysql::phabricator
    $mysql_adminuser       = $passwords::mysql::phabricator::admin_user
    $mysql_adminpass       = $passwords::mysql::phabricator::admin_pass
    $mysql_appuser         = $passwords::mysql::phabricator::app_user
    $mysql_apppass         = $passwords::mysql::phabricator::app_pass
    $mysql_maniphestuser   = $passwords::mysql::phabricator::manifest_user
    $mysql_maniphestpass   = $passwords::mysql::phabricator::manifest_pass
    $bz_user               = $passwords::mysql::phabricator::bz_user
    $bz_pass               = $passwords::mysql::phabricator::bz_pass
    $rt_user               = $passwords::mysql::phabricator::rt_user
    $rt_pass               = $passwords::mysql::phabricator::rt_pass

    include passwords::phabricator
    $phabtools_cert        = $passwords::phabricator::phabtools_cert
    $phabtools_user        = $passwords::phabricator::phabtools_user
    $gerritbot_token       = $passwords::phabricator::gerritbot_token
}

