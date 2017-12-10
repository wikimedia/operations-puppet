class snapshot::dumps(
    $xmldumpsmount = undef,
) {
    include ::snapshot::dumps::packages
    class { '::snapshot::dumps::configs':
        xmldumpsmount  => $xmldumpsmount,
    }
    include ::snapshot::dumps::dblists
    include ::snapshot::dumps::templates
    include ::snapshot::dumps::stagesconfig
}
