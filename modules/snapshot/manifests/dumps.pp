class snapshot::dumps(
    $xmldumpsmount = undef,
    $miscdumpsmount = undef,
) {
    include ::snapshot::dumps::packages
    class { '::snapshot::dumps::configs':
        xmldumpsmount  => $xmldumpsmount,
        miscdumpsmount => $miscdumpsmount,
    include ::snapshot::dumps::dblists
    include ::snapshot::dumps::templates
    include ::snapshot::dumps::stagesconfig
}
