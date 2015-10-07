# redirect http://irc.wikimedia.org to http://meta.wikimedia.org/wiki/IRC
class mw_rc_irc::apache {
    apache::site { 'irc.wikimedia.org':
        content => template('mw_rc_irc/apache/irc.wikimedia.org.erb'),
    }
}

