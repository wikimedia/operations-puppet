# let users publish their own HTML in their home dirs
class role::microsites::peopleweb {

    include ::standard
    include ::base::firewall

    class { '::publichtml':
        sitename     => 'people.wikimedia.org',
        server_admin => 'noc@wikimedia.org',
    }

    ferm::service { 'people-http':
        proto => 'tcp',
        port  => '80',
    }

    motd::script { 'people-motd':
        ensure  => present,
        content => "#!/bin/sh\necho '\nThis is people.wikimedia.org.\nFiles you put in 'public_html' in your home dir will be accessible on the web.\nMore info on https://wikitech.wikimedia.org/wiki/People.wikimedia.org.\n'",
    }

    backup::set {'home': }
}

