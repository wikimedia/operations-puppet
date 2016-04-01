define snapshot::dumps::wikiconf(
    $configtype = 'smallwikis',
    $config     = undef,
    ) {

    include snapshot::dumps::dirs
    $apachedir = $snapshot::dumps::dirs::apachedir

    file { "${snapshot::dumps::dirs::dumpsdir}/confs/${title}":
        ensure  => 'present',
        path    => "${snapshot::dumps::dirs::dumpsdir}/confs/${title}",
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        content => template('snapshot/wikidump.conf.erb'),
    }
}
