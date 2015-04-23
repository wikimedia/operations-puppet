# == Define: diamond::collector::extendedexim
#
# Exim collector. Collects queue properties and paniclog size.
#
# Queue properties:
#     - queue.oldest: age of oldest e-mail in queue (seconds)
#     - queue.youngest: age of youngest e-mail in queue (seconds)
#     - queue.size: total size of the queue (bytes)
#     - queue.length: total number of e-mails in the queue
#     - queue.num_frozen: number of frozen e-mails in the queue
#
# Paniclog properties:
#     - paniclog.length: number of lines in /var/log/exim4/paniclog

include stdlib

define diamond::collector::extendedexim(
    $settings = {},
    $ensure   = present,
) {
    $default_settings = {'use_sudo' => 'true'}
    $merged_settings = merge($default_settings, $settings)

    diamond::collector { 'ExtendedExim':
        settings => $merged_settings,
        source  => 'puppet:///modules/diamond/collector/extendedexim.py',
        ensure => $ensure,
    }

    if str2bool($merged_settings[use_sudo]) {
        sudo::user { 'diamond_sudo_for_exim':
            user       => 'diamond',
            privileges => ['ALL=(root) NOPASSWD: /usr/sbin/exim, /bin/cat /var/log/exim4/paniclog'],
            ensure => $ensure,
        }
    }
}
