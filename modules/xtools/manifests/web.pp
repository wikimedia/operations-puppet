class xtools::web(
    $host
) {
    ::apache::site { "xtools-$host":
        ensure => present,
        content => template('xtools/xtools.conf.erb'),
    }

    require apache::mod::php7
}
