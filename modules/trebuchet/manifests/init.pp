# == Class: trebuchet
#
# Trebuchet is a SaltStack-based, two-stage deployment system that we
# use to deploy software that we develop internally or that changes
# rapidly enough to make Debianization impractical.
#
class trebuchet(
    $deployment_server = $::deployment_server_override
) {
    $trebuchet_master = $::realm ? {
        labs       => pick($deployment_server, "${::labsproject}-deploy.${::labsproject}.eqiad.wmflabs"),
        default    => hiera('deployment_server','tin.eqiad.wmnet'),
    }
}
