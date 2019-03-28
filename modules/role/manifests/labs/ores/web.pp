# filtertags: labs-project-ores
class role::labs::ores::web {
    include ::profile::ores::web
    include ::role::labs::ores::redisproxy
}
