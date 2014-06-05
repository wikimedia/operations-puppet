class webserver::apache {
    include packages
    include config
    include service
    include webserver::base
}
