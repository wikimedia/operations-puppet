class role::prometheus::mysqld_exporter {
    include passwords::prometheus

    prometheus::mysqld_exporter { 'default':
        client_password => $passwords::prometheus::db_pass,
    }

    ferm::service { 'prometheus-mysqld-exporter':
        proto  => 'tcp',
        port   => '9104',
        srange => '$INTERNAL',
    }
}
