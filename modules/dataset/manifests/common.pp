class dataset::common {
    package { 'rsync':
        ensure => present,
    }

    include ::vm::higher_min_free_kbytes
}
