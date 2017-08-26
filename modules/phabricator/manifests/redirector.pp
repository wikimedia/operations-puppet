# == Class: phabricator::redirector
#
# Setup the preamble.php and redirect_config.json to redirect bugzilla
# (and eventually RT) urls to phabricator
#
# [*field_index*]
#   This is the index value for the ext_reference custom field

define phabricator::redirector(
    $mysql_user,
    $mysql_pass,
    $mysql_host,
    $rootdir     = '/srv/phab',
    $field_index = '',
    $phab_host   = 'phabricator.wikimedia.org',
    $alt_host    = 'phab.wmfusercontent.org'
) {
    $preamble = "${phabricator::confdir}/preamble.php"
    $redirect_config = "${phabricator::confdir}/redirect_config.json"

    file { "${rootdir}/phabricator/support/preamble.php":
        ensure => 'link',
        target => $preamble
    }
    file { $preamble:
        content => template('phabricator/preamble.php.erb'),
    }

    file { $redirect_config:
        content => template('phabricator/redirect_config.json.erb'),
    }
    file { "${rootdir}/phabricator/support/redirect_config.json":
        ensure => 'link',
        target => $redirect_config,
    }
}
