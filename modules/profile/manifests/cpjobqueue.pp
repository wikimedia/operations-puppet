# == Class: profile::cpjobqueue
#
# profile::cpjobqueue is the profile class for ChangeProp for JobQueue, a
# special instance of ChangePropagation that is used to pick up job definitions
# from the main Kafka cluster (EventBus) and sends them for execution on the
# jobrunners.
#
# === Parameters
#
# [*redis_path*]
#   The path to Redis' UNIX socket. Note that the password is taken directly
#   from the private repository with secrets.
#
# [*jobrunner_host*]
#   The address of the LVS end point for jobrunners.
#
# [*kafka_msg_max_bytes*]
#   The maximum allowed message size in Kafka. This value *must* match the
#   brokers' configuration of the same name.
#
class profile::cpjobqueue(
    $redis_path          = hiera('profile::cpjobqueue::redis_path'),
    $jobrunner_host      = hiera('profile::cpjobqueue::jobrunner_host'),
    $kafka_msg_max_bytes = hiera('kafka_message_max_bytes'),
) {

    include ::passwords::redis
    require ::changeprop::packages

    $kafka_config = kafka_config('main')

    service::node { 'cpjobqueue':
        port              => 7200,
        healthcheck_url   => '',
        has_spec          => true,
        deployment        => 'scap3',
        deployment_config => true,
        deployment_vars   => {
            broker_list     => $kafka_config['brokers']['string'],
            site            => $::site,
            redis_path      => $redis_path,
            redis_pass      => $::passwords::redis::main_password,
            jobrunner_uri   => "${jobrunner_host}/rpc/RunSingleJob.php",
            kafka_max_bytes => $kafka_msg_max_bytes,
        },
        auto_refresh      => false,
        init_restart      => false,
        environment       => {
            'UV_THREADPOOL_SIZE' => 128,
        },
    }
}
