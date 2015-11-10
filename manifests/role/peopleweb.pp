class role::peopleweb {

    include standard

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
}

class role::peopleweb::migration {

    $sourceip='10.64.32.13'

    ferm::service { 'peopleweb-migration-rysnc':
        proto  => 'tcp',
        port   => '873',
        srange => "${sourceip}/32",
    }

    include rsync::server

    rsync::server::module { 'people-homes':
        path        => '/home',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

}

