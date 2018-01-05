# let users publish their own HTML in their home dirs
class profile::microsites::peopleweb {

    class { '::httpd':
        modules => ['userdir', 'cgi', 'php5', 'rewrite', 'headers'],
    }

    class { '::publichtml':
        sitename     => 'people.wikimedia.org',
        server_admin => 'noc@wikimedia.org',
    }

    motd::script { 'people-motd':
        ensure  => present,
        content => "#!/bin/sh\necho '\nThis is people.wikimedia.org.\nFiles you put in 'public_html' in your home dir will be accessible on the web.\nMore info on https://wikitech.wikimedia.org/wiki/People.wikimedia.org.\n'",
    }

    backup::set {'home': }
}

