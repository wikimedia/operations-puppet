define phabricator::redirector($mysql_user, $mysql_pass, $mysql_host, $rootdir='/', $field_index='', $phab_host='phabricator.wikimedia.org') {
    file { "${rootdir}/phabricator/support/preamble.php":
        content => template('phabricator/preamble.php.erb')
        require => File["${rootdir}/phabricator/support/redirect_config.json"]
    }

    file { "${rootdir}/phabricator/support/redirect_config.json":
        content => template('phabricator/redirect_config.json.erb')
    }
}
