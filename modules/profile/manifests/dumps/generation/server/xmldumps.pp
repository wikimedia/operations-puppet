class profile::dumps::generation::server::xmldumps(
    $dumps_single_backend = lookup('profile::dumps::single_backend'),
    $internals = lookup('profile::dumps::internal'),
    $publics = lookup('profile::dumps::public'),
    $xmldumpsdir = lookup('profile::dumps::xmldumpsdir'),
) {
    require profile::dumps::generation::server::common

    if (!$dumps_single_backend) {

        $internaldests = $internals.map |$i| {"${i}::data/xmldatadumps/public/"}.join(',')
        $xmlpublicdests = $publics.map |$p| {"${p}::data/xmldatadumps/public/"}.join(',')

        class { '::dumps::generation::server::rsyncer_xml':
            xmldumpsdir   => $xmldumpsdir,
            xmlremotedirs => "${internaldests},${xmlpublicdests}",
        }
    }
}
