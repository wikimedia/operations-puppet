define snapshot::dumps::wikiconf(
    $configtype = 'allwikis',
    $config     = undef,
    $publicdir  = '/mnt/data/xmldatadumps/public',
    $privatedir = '/mnt/data/xmldatadumps/private',
    $tempdir    = '/mnt/data/xmldatadumps/temp',
    ) {
    $confsdir = $snapshot::dumps::dirs::confsdir

    file { "${confsdir}/${title}":
        ensure  => 'present',
        path    => "${confsdir}/${title}",
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        content => template('snapshot/dumps/wikidump.conf.erb'),
    }
}
