# New style attempt at handling misc web servers
# - keep independent from the existing stuff
class webserver::apache {

    # Realize virtual resources for enabling virtual hosts
    Webserver::Apache::Site <| |>

    include webserver::sysctl_settings
}
