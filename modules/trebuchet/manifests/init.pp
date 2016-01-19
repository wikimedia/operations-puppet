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
        labs       => pick($deployment_server, "${::labsproject}-deploy.eqiad.wmflabs"),
        default    => hiera('deployment_server','tin.eqiad.wmnet'),
    }

    include ::trebuchet::packages

    salt::grain { 'trebuchet_master':
        value   => $trebuchet_master,
        replace => true,
    }

    # Trebuchet needs salt-minion to query grains, and it needs the
    # `trebuchet_master` grain set so that it knows where to fetch from.
    # It also needs the dependencies from ::trebuchet::packages.
    Service['salt-minion'] ->
        Salt::Grain['trebuchet_master'] ->
            Class['::trebuchet::packages'] ->
                Package <| provider == 'trebuchet' |>
}
