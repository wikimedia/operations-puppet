class wikilabels::session {

    class{ '::memcached':
        ip   => '127.0.0.1',
        port => '11211',
    }
}