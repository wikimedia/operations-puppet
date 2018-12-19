# vim:sw=4 ts=4 sts=4 et:

# = Define: logstash::input::tcp
#
# Configure logstash to collect input via a tcp socket.
#
# == Parameters:
# - $ensure: Whether the config should exist. Default 'present'.
# - $port: Port to listen for udp2log input on. Default '5229'.
# - $codec: Codec to decode tcp stream input. Default 'plain'.
# - $priority: Configuration loading priority. Default '10'.
# - $ssl_enable: Enable/disable ssl support in logstash input. Default false.
# - $ssl_cert: Path to ssl certificate file. Requred when ssl is enabled.
# - $ssl_key: Path to ssl key file. Required when ssl is enabled.
# - $plugin_id: Name associated with Logstash metrics
#
# == Sample usage:
#
#   logstash::input::tcp {
#       port  => 5229,
#       codec => 'json_lines',
#   }
#
define logstash::input::tcp(
    Wmflib::Ensure   $ensure     = present,
    String           $type       = 'tcp',
    String           $codec      = 'plain',
    Integer          $port       = 5229,
    Integer          $priority   = 10,
    Boolean          $ssl_enable = false,
    Optional[String] $ssl_cert   = undef,
    Optional[String] $ssl_key    = undef,
    String           $plugin_id  = "input/tcp/${port}",
    Optional[Array]  $tags       = undef,
) {

    # Ensure cert/key params look like filesystem paths when ssl is enabled.
    if $ssl_enable == true {
      validate_absolute_path($ssl_cert)
      validate_absolute_path($ssl_key)
    }

    logstash::conf { "input-tcp-${title}":
        ensure   => $ensure,
        content  => template('logstash/input/tcp.erb'),
        priority => $priority,
    }
}
