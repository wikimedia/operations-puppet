# == Class: phabricator::bot
#
class phabricator::bot (
    String $username,
    String $token,
    String $host  = 'https://phabricator.wikimedia.org/api/',
    String $owner = 'root',
    String $group = 'root',
    String $mode  = '0440',
) {

    file { "/etc/phabricator_${username}.conf":
        ensure  => file,
        content => template('phabricator/bot.conf.erb'),
        owner   => $owner,
        group   => $group,
        mode    => $mode,
    }
}
