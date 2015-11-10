#= Class restbase::config
#
# Add configuration files for restbase
#
# === Parameters
#
# [*owner*]
#   User that should own the configuration directory
# [*group*]
#   Group that should own the configuration directory
# [*config_template*]
#   File to use as the configuration file template.
#   Default: restbase/config.yaml.erb

class restbase::config (
    $owner = 'root',
    $group = 'root',
    $config_template = 'restbase/config.yaml.erb',
) {
    file { '/etc/restbase':
        ensure => directory,
        owner  => $owner,
        group  => $group,
        mode   => '0755',
        before => Service['restbase'],
    }

    file { '/etc/restbase/config.yaml':
        content => template($config_template),
        owner   => $owner,
        group   => $group,
        mode    => '0444',
        tag     => 'restbase::config',
    }
}
