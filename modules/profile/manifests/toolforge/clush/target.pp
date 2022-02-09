# remove remains of clustershell
class profile::toolforge::clush::target () {
    clush::target { 'clushuser':
        ensure => absent,
    }

    # Allow `clushuser` to SSH into the instance.
    security::access::config { 'clushuser':
        ensure => absent,
    }

    # Give `clushuser` complete sudo rights
    sudo::user { 'clushuser':
        ensure     => absent,
        privileges => [],
    }
}
