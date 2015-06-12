class pybal {

    package { [ 'ipvsadm', 'pybal' ]:
        ensure => installed;
    }
}
