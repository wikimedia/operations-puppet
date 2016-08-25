# = Class: striker::nginx
#
# Deprecated nginx reverse proxy.
# Will be removed in a follow up commit.
class striker::nginx {
    class { '::nginx':
        ensure  => absent,
        variant => 'light',
    }
    nginx::site { 'striker':
        ensure  => absent,
    }
}
# vim:sw=4:ts=4:sts=4:ft=puppet:
