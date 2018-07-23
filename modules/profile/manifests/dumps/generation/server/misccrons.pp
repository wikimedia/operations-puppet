class profile::dumps::generation::server::misccrons(
    $dumps_single_backend = lookup('profile::dumps::single_backend'),
    $internals = lookup('profile::dumps::internal'),
    $publics = lookup('profile::dumps::public'),
    $miscdumpsdir = lookup('profile::dumps::miscdumpsdir'),
    $miscsubdirs = lookup('profile::dumps::miscsubdirs'),
) {
    require profile::dumps::generation::server::common

    if (!$dumps_single_backend) {
        $miscinternaldests = $internals.map |$i| {"${i}::data/otherdumps/"}.join(',')
        $miscpublicdests = $publics.map |$p| {"${p}::data/xmldatadumps/public/other/"}.join(',')

        class { '::dumps::generation::server::rsyncer':
            miscdumpsdir   => $miscdumpsdir,
            miscremotedirs => "${miscinternaldests},${miscpublicdests}",
            miscsubdirs    => $miscsubdirs,
            miscremotesubs => $miscinternaldests,
        }
    }
}
