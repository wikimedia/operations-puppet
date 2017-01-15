class snapshot::dumps {
    include ::snapshot::dumps::packages
    include ::snapshot::dumps::configs
    include ::snapshot::dumps::dblists
    include ::snapshot::dumps::templates
    include ::snapshot::dumps::stagesconfig
}
