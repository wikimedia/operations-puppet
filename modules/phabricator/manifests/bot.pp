# == Class: phabricator::bot
#
class phabricator::bot (
    $username,
    $token,
    $host     = 'https://phabricator.wikimedia.org/api/',
    $owner    = 'root',
    $group    = 'root',
    $mode     = '0440',
) {

    file { "/etc/phabricator_${username}.conf":
        ensure  => file,
        content => template('phabricator/bot.conf.erb'),
        owner   => $owner,
        group   => $group,
        mode    => $mode,
    }
}
