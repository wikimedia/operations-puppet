define snapshot::dumps::wikiconf(
    $configtype = 'smallwikis',
    $config     = undef,
    ) {

    include snapshot::dirs

    file { "${snapshot::dirs::dumpsdir}/confs/${title}":
        ensure  => 'present',
        path    => "${snapshot::dirs::dumpsdir}/confs/${title}",
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        content => template('snapshot/wikidump.conf.erb'),
    }
}
