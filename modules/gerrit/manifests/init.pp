# Manifest to setup a Gerrit instance

class gerrit($host) {

    class { 'gerrit::jetty': }

    class { 'gerrit::proxy':
        require => Class['gerrit::jetty'],
    }

    class { 'gerrit::crons':
        require => Class['gerrit::jetty'],
    }
}
