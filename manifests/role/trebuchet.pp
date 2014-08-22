# == Class: role::trebuchet
#
# Trebuchet is a SaltStack-based, two-stage deployment system that we
# use to deploy software that we develop internally or that changes
# rapidly enough to make Debianization impractical.
#
class role::trebuchet {
    $trebuchet_master = $::realm ? {
        production => 'tin.eqiad.wmnet',
        labs       => pick($::trebuchet_master_override, "${::instanceproject}-deploy.eqiad.wmflabs"),
    }

    salt::grain { 'trebuchet_master':
        value   => $trebuchet_master,
        replace => true,
    }

    # Trebuchet needs salt-minion to query grains, and it needs the
    # `trebuchet_master` grain set so that it knows where to fetch from.
    Service['salt-minion'] ->
        Salt::Grain['trebuchet_master'] ->
            Package <| provider == 'trebuchet' |>
}
