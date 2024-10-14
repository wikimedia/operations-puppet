# SPDX-License-Identifier: Apache-2.0
class profile::dumps::generation::server::xmldumps(
    $dumps_single_backend = lookup('profile::dumps::single_backend'),
    $internals = lookup('profile::dumps::internal'),
    $publics = lookup('profile::dumps::public'),
    $xmldumpsdir = lookup('profile::dumps::xmldumpsdir'),
) {
    require profile::dumps::generation::server::common

    if (!$dumps_single_backend) {

        $xmlpublicdests = $publics.map |$p| {"${p}::data/xmldatadumps/public/"}.join(',')

        if !empty($internals) {
            $internaldests = $internals.map |$i| {"${i}::data/xmldatadumps/public/"}.join(',')
            $xmlremotedirs = "${internaldests},${xmlpublicdests}"
        } else {
            $xmlremotedirs = $xmlpublicdests
        }

        class { '::dumps::generation::server::rsyncer_xml':
            xmldumpsdir   => $xmldumpsdir,
            xmlremotedirs => $xmlremotedirs,
        }
    }
}
