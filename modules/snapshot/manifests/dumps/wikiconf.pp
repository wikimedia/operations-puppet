define snapshot::dumps::wikiconf(
    $configtype = 'allwikis',
    $config     = undef,
    ) {

    include ::snapshot::dumps::dirs
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
