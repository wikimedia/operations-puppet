# == Class kartotherian::nagios::check
# Sets up icinga alerts for Kartotherian.
#
class kartotherian::nagios::check {

    # Check that Kartotherian can actually generate a tile. This should ensure
    # that Kartotherian itself works and that it can talk to its storage
    # backend (Cassandra).
    monitoring::service { 'kartotherian-http-tile-check':
        ensure        => present,
        description   => 'Kartotherian tile generation',
        check_command => "check_http_port_url!6533!http://localhost/osm-intl/0/0/0.png",
    }

}
