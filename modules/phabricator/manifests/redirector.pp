define phabricator::redirector($mysql_user, $mysql_pass, $mysql_host, $rootdir='/', $field_index='', $phab_host='phabricator.wikimedia.org') {
    file { "${rootdir}/phabricator/support/preamble.php":
        source  => 'puppet:///modules/phabricator/preamble.php',
        require => File["${rootdir}/phabricator/support/redirect_config.json"]
    }

    file { "${rootdir}/phabricator/support/redirect_config.json":
        content => template('phabricator/redirect_config.json.erb')
    }
}
