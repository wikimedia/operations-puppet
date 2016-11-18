class varnish::apt_preferences {
    # XXX: to remove
    apt::pin { 'varnish':
        ensure   => 'absent',
        pin      => '',
        priority => '',
    }
}
