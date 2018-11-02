# == Define: phabricator::conf_env
# Creates a environment-specific config file which can be activated with
# the environment variable `PHABRICATOR_ENV`
#
# When active, any config keys in this file override keys in the standard
# phabricator config file `local.json`
#
define phabricator::conf_env(
    String $environment,
    Hash $phab_settings = {},
    String $owner       = 'root',
    String $group       = 'root',
) {
    file { "${phabricator::confdir}/local/${environment}.json":
        owner   => $owner,
        group   => $group,
        mode    => '0640',
        content => template('phabricator/local.json.erb'),
        require => [Package[$phabricator::deploy_target]],
    }
}
