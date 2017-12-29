class snapshot::dumps(
    $php = undef,
) {
    include ::snapshot::dumps::packages
    class {'::snapshot::dumps::configs': php => $php}
    include ::snapshot::dumps::dblists
    include ::snapshot::dumps::templates
    include ::snapshot::dumps::stagesconfig
}
