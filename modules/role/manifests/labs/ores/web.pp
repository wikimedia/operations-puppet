# filtertags: labs-project-ores
class role::labs::ores::web {
    include ::ores::web
    include ::role::labs::ores::redisproxy
}
