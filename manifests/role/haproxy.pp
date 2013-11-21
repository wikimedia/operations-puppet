class role::haproxy{
    system::role { 'haproxy': description => 'haproxy host' }

    include haproxy
}
