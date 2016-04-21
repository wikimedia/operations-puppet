# http://apt.wikimedia.org/wikimedia/
class role::aptrepo::wikimedia {

    class { '::aptrepo':
        basedir => '/srv/wikimedia',
    }

}
