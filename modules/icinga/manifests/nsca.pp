
# NSCA - Nagios Service Check Acceptor
# package contains daemon and client script
class icinga::nsca {

    package { 'nsca':
        ensure => latest,
    }

}

