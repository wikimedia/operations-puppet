# Standard installation of dsh (Dancer's distributed shell)

class dsh {

    package { 'dsh':
        ensure => present
    }

    include dsh::files

}

