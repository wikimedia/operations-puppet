# === Class profile::keyholder::server
#
# Sets up the keyholder agents on a server.
#
# === Parameters
#
# [*agents*] List of keyholder::agent instances to declare.
class profile::keyholder::server(
    $agents = hiera('profile::keyholder::server::agents', {})
) {
    class { '::keyholder':
        require_encrypted_keys => 'yes',
    }
    class { '::keyholder::monitoring':
    }

    $agents.each |$name, $params| {
        keyholder::agent{ $name:
            * => $params
        }
    }
}
