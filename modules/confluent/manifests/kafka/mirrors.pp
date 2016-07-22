# == Class confluent::kafka::mirrors
# Creates and configures MirrorMaker instances as defined in
# $mirrors.  $mirrors should map names to
# confluent::kafka::mirror::instance parameters.
#
# == Parameters
# [*mirrors*]
#   A hash mapping mirror names to confluent::kafka::mirror::
#   parameters.
#
# [*mirror_defaults*]
#   Default values to provide to confluent::kafka::mirror::instance if
#   they are not specified in an element in $mirrors.
#
# == Usage
# # Set up mirror instances to mirror both Kafka clusters mainA and mainB
# # to an aggregate cluster.  Note that if you are running multiple
# # mirror instances on a single host, you must specify unique
# # jmx_ports for each of them.
# class { 'confluent::kafka::mirrors:
#     $mirrors => {
#         'mainA_to_aggregate' => {
#             'zookeeper_url' => 'zk1:2181/kafka/mainA'
#             'jmx_port'      => 9995,
#         },
#         'mainB_to_aggregate' => {
#             'zookeeper_url' => 'zk1:2181/kafka/mainB'
#             'jmx_port'      => 9994,
#         },
#     },
#     mirror_defaults => {
#         'destination_brokers' => 'agg1:9092,agg2:9092'
#         'whitelist'           => 'my_topics\..+',
#         'num_streams'         => 2,
#     }
# }
#
class confluent::kafka::mirrors(
    $mirrors,
    $mirror_defaults
)
{
    create_resources(
        'confluent::kafka::mirror::instance',
        $mirrors,
        $mirror_defaults,
    )
}
