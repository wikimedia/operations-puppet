# Profile class for changeprop
#
# filtertags: labs-project-deployment-prep
class profile::changeprop(
    $restbase_uri = hiera('profile::changeprop::restbase_uri'),
    $purge_host  = hiera('profile::changeprop::purge_host'),
    $purge_port  = hiera('profile::changeprop::purge_port'),
    $ores_uris  = hiera('profile::changeprop::ores_uris'),
    $event_service_uri = hiera('profile::changeprop::event_service_uri'),
    $kafka_msg_max_bytes = hiera('kafka_message_max_bytes', 1048576),
) {

    include ::passwords::redis
    require ::profile::changeprop::packages

    $kafka_config = kafka_config('main')
    $broker_list = $kafka_config['brokers']['string']
    $redis_path = "/var/run/nutcracker/redis_${::site}.sock"
    $redis_pass = $::passwords::redis::main_password

    service::node { 'changeprop':
        enable            => true,
        port              => 7272,
        healthcheck_url   => '',
        has_spec          => true,
        deployment        => 'scap3',
        deployment_config => true,
        deployment_vars   => {
            broker_list       => $broker_list,
            restbase_uri      => $restbase_uri,
            ores_uris         => $ores_uris,
            event_service_uri => $event_service_uri,
            purge_host        => $purge_host,
            purge_port        => $purge_port,
            site              => $::site,
            redis_path        => $redis_path,
            redis_pass        => $redis_pass,
            kafka_max_bytes   => $kafka_msg_max_bytes,
        },
        auto_refresh      => false,
        init_restart      => false,
        environment       => {
            'UV_THREADPOOL_SIZE' => 128,
        },
    }
}
