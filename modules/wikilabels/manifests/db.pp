class wikilabels::db {

    class { '::postgresql::server':
    }

    postgresql::user { 'wikilabels@localhost'
        ensure   => 'present',
        user     => 'wikilabels',
        password => '',
        cidr     => '127.0.0.1/32',
        method   => 'trust',
    }
}