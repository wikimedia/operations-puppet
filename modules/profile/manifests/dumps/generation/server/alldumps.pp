class profile::dumps::generation::server::alldumps(
    $dumps_single_backend = lookup('profile::dumps::single_backend'),
    $internals = lookup('profile::dumps::internal'),
    $publics = lookup('profile::dumps::public'),
    $xmldumpsdir = lookup('profile::dumps::xmldumpsdir'),
    $miscdumpsdir = lookup('profile::dumps::miscdumpsdir'),
    $miscsubdirs = lookup('profile::dumps::miscsubdirs'),
) {
    require profile::dumps::generation::server::common

    if (!$dumps_single_backend) {
        $internaldests = $internals.map |$i| {"${i}::data/xmldatadumps/public/"}.join(',')
        $xmlpublicdests = $publics.map |$p| {"${p}::data/xmldatadumps/public/"}.join(',')
        $miscinternaldests = $internals.map |$i| {"${i}::data/otherdumps/"}.join(',')
        $miscpublicdests = $publics.map |$p| {"${p}::data/xmldatadumps/public/other/"}.join(',')

        class { '::dumps::generation::server::rsyncer_all':
            xmldumpsdir    => $xmldumpsdir,
            xmlremotedirs  => "${internaldests},${xmlpublicdests}",
            miscdumpsdir   => $miscdumpsdir,
            miscremotedirs => $miscpublicdests,
            miscsubdirs    => $miscsubdirs,
            miscremotesubs => $miscinternaldests,
        }
    }
}
