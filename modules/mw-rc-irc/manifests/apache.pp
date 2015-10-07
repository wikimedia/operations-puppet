# redirect http://irc.wikimedia.org to http://meta.wikimedia.org/wiki/IRC
class mw-rc-irc::apache {
    apache::site { 'irc.wikimedia.org':
        content => template('mw-rc-irc/apache/irc.wikimedia.org.erb'),
    }
}

