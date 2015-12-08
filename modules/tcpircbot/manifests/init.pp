# == Class: tcpircbot
#
# Base class for tcpircbot, a daemon that reads messages from a TCP socket and
# writes them to an IRC channel. You should not need to override the defaults
# for this class's parameters. You likely need to simply 'include tcpircbot'
# and then provision an instance by declaring a 'tcpircbot::instance' resource.
# See instance.pp for the configuration options you do need to specify.
#
# === Parameters
#
# [*dir*]
#   Directory for tcpircbot script and configuration files and home directory
#   for user.
#
# === Examples
#
# The following snippet will configure a bot nicknamed 'announcebot' that will
# sit on #wikimedia-operations on Freenode and forward messages that come in
#from private and loopback IPs on port 9200:
#
#   include tcpircbot
#
#   tcpircbot::instance { 'announcebot':
#     channels => ['#wikimedia-operations'],
#     password => $passwords::irc::announcebot,
#   }
#
class tcpircbot(
    $dir         = '/srv/tcpircbot',
) {

    if os_version('debian >= jessie') {
        require_package(['python-irclib', 'python-netaddr'])
    } else {
        require_package(['python-irc', 'python-netaddr'])
    }

    group { 'tcpircbot':
        ensure  => present,
        name    => 'tcpircbot',
    }

    user { 'tcpircbot':
        ensure     => present,
        gid        => 'tcpircbot',
        shell      => '/bin/false',
        home       => $dir,
        managehome => true,
        system     => true,
        require    => Group['tcpircbot'],
    }

    file { "${dir}/tcpircbot.py":
        ensure => present,
        source => 'puppet:///modules/tcpircbot/tcpircbot.py',
        owner  => 'tcpircbot',
        group  => 'tcpircbot',
        mode   => '0555',
    }
}
