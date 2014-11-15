# setup the preamble.php and redirect_config.json to redirect bugzilla
# (and eventually RT) urls to phabricator
define phabricator::redirector(
    $mysql_user,
    $mysql_pass,
    $mysql_host,
    $rootdir     = '/srv/phab',
    $field_index = '',
    $phab_host   = 'phabricator.wikimedia.org',
    $alt_host    = 'fab.wmfusercontent.org'
) {
    file { "${rootdir}/phabricator/support/preamble.php":
        content => template('phabricator/preamble.php.erb'),
        require => File["${rootdir}/phabricator/support/redirect_config.json"]
    }

    file { "${rootdir}/phabricator/support/redirect_config.json":
        content => template('phabricator/redirect_config.json.erb')
    }
}
