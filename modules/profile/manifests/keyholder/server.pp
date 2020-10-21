# === Class profile::keyholder::server
#
# Sets up the keyholder agents on a server.
#
# === Parameters
#
# [*agents*] List of keyholder::agent instances to declare.
class profile::keyholder::server(
    Hash $agents = lookup('profile::keyholder::server::agents', { 'default_value' => {}}),
    Stdlib::Yes_no $require_encrypted_keys = lookup('profile::keyholder::server::require_encrypted_keys', { 'default_value' => 'yes' }),
){

    class { '::keyholder':
        require_encrypted_keys => $require_encrypted_keys,
    }
    class { '::keyholder::monitoring':
    }

    $agents.each |$name, $params| {
        keyholder::agent{ $name:
            * => $params
        }
    }
}
