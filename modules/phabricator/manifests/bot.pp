# == Class: phabricator::bot
#
class phabricator::bot (
    $owner    = 'root',
    $group    = 'root',
    $mode     = '0440',
    $host     = 'https://phabricator.wikimedia.org/api/',
    $username = '',
    $token    = '',
) {

    file { "/etc/phabricator_${username}.conf":
        ensure  => file,
        content => template('phabricator/bot.conf.erb'),
        owner   => $owner,
        group   => $group,
        mode    => $mode,
    }
}
