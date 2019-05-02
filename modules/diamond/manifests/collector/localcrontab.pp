# == Define: diamond::collector::localcrontab
#
# crontab collector.  Collects number of crontabs.
#
# Properties:
#     - localcrontab.total: Total number of crontabs.
#     - localcrontab.administrative: Number of crontabs of
#       administrative users.
#     - localcrontab.other: Number of other crontabs.

define diamond::collector::localcrontab(
    $settings = {},
    $ensure   = present,
    String $sudo_flavor = 'sudo',
) {

    # lint:ignore:quoted_booleans
    # This is jammed straight into a config file, needs quoting.
    $default_settings = {'use_sudo' => 'true'}
    # lint:endignore
    $merged_settings = merge($default_settings, $settings)

    diamond::collector { 'LocalCrontabCollector':
        ensure   => $ensure,
        settings => $merged_settings,
        source   => 'puppet:///modules/diamond/collector/localcrontab.py',
    }

    if str2bool($merged_settings[use_sudo]) {
        sudo::user { 'diamond_sudo_for_localcrontab':
            ensure      => $ensure,
            user        => 'diamond',
            privileges  => ['ALL=(root) NOPASSWD: /bin/ls /var/spool/cron/crontabs/'],
            sudo_flavor => $sudo_flavor,
        }
    }
}
