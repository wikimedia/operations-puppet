class role::labs::ores::web {
    include ::ores::web
    include ::role::labs::ores::redisproxy

    ores::config { "main":
        config   => {
            "ores"             => {
                "data_paths" => {
                    "nltk" => "${ores::base::config_path}/submodules/wheels/nltk/",
                }
            },
            "score_caches"     => {
                "ores_redis" => {
                    "host" => ores::redisproxy::server,
                    "port" => "6380",
                }
            },
            "score_processors" => {
                "ores_celery" => {
                    "BROKER_URL"            => "redis://${ores::redisproxy::server}:6379",
                    "CELERY_RESULT_BACKEND" => "redis://${ores::redisproxy::server}:6379",
                }
            },
        },
        priority => "99",
    }
}
