# Profile to setup and configure wmfmariadbpy libraries and
# utilities.
# When we have a more complete profile::mariadb::common we can probably fold this into that
class profile::mariadb::wmfmariadbpy (
    Wmfmariadbpy::Role         $role          = lookup('profile::mariadb::wmfmariadbpy::role', {'default_value' => 'db'}),
    Hash[String, Stdlib::Port] $section_ports = lookup('profile::mariadb::section_ports'),
) {
    class {'wmfmariadbpy':
        role          => $role,
        section_ports => $section_ports,
    }
}

