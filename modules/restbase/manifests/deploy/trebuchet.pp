# == Class restbase::deploy::trebuchet
#
# Ensures that restbase target is setup correctly for deployment via trebuchet
#
class restbase::deploy::trebuchet {
    class { restbase::config:
        owner => $config_owner,
        group => $config_group,
    }
}
