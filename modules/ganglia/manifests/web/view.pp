# == Define ganglia::web::view
# Defines a Ganglia view JSON file.
# See http://sourceforge.net/apps/trac/ganglia/wiki/ganglia-web-2#JSONdefinitionforviews
# for documentation on Ganglia view JSON format.
#
# == Parameters:
# $graphs       - Shortcut for describing items that represent aggregate_graphs.
# $items        - Should match exactly the JSON structure expected by Ganglia for views.
# $view_type    - If you are using aggregate_graphs, this must be set to 'standard'.
#                 'regex' will allow you to use non-aggregate graphs and match hostnames by regex.
#                 Default: 'standard'.
# $default_size - Default size for graphs.  Default: 'large'.
# $conf_dir     - Path to directory where ganglia view JSON files should live.
#                 Defaults to the appropriate directory based on WMF $::realm.  Default: /var/lib/ganglia/conf.
# $template     - The ERB template to use for the JSON file.  Only change this if you need to do fancier things than this define allows.
#
# == Examples:
# # A 'regex' (non-aggregate graph) view:
# # Note that no aggregate_graphs are used.
# # This will add 4 graphs to the 'cpu' view.
# # (i.e. cpu_user and cpu_system for each myhost0 and myhost1)
# $host_regex = 'myhost[01]'
# ganglia::view { 'cpu':
#   view_type => 'regex',
#   items     => [
#     {
#       'metric'   => 'cpu_user',
#       'hostname' => $host_regex,
#     }
#     {
#       'metric'   => 'cpu_system',
#       'hostname' => $host_regex,
#     }
#   ],
# }
#
#
# # Use the $graphs parameter to describe aggregate graphs.
# # You can describe the same graphs to add with $items.
# # $graphs is just a shortcut.  aggregate_graphs in $items
# # are a bit overly verbose.
# $host_regex = 'erbium|oxygen|gadolinium'
# ganglia::view { 'udp2log':
#   graphs => [
#     {
#       'host_regex'   => $host_regex,
#       'metric_regex' => 'packet_loss_average',
#     }
#     {
#       'host_regex'   => $host_regex,
#       'metric_regex' => 'drops',
#     }
#     {
#       'host_regex'   => $host_regex,
#       'metric_regex' => 'packet_loss_90th',
#     }
#   ],
# }
#
define ganglia::web::view(
    $graphs       = [],
    $items        = [],
    $view_type    = 'standard',
    $default_size = 'large',
    $conf_dir     = '/var/lib/ganglia-web/conf',
    $description  = undef,
    $ensure       = 'present'
)
{
    if $description {
        $view_name = $description
    } else {
        $view_name = $name
    }
    file { "${conf_dir}/view_${name}.json":
        ensure  => $ensure,
        content => template('ganglia/ganglia_view.json.erb'),
    }
}
