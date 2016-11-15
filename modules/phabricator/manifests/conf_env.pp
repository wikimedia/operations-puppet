# == Define: phabricator::conf_env
define phabricator::conf_env(
    $name           = $title,
    $phab_settings  = {},
    $owner          = 'root',
    $group          = 'root',
) {
    file { "${phabricator::phabdir}/phabricator/conf/local/${name}.json":
        owner   => $owner,
        group   => $group,
        mode    => '0640',
        content => template('phabricator/local.json.erb'),
    }
}
