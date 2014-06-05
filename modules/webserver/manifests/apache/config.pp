class webserver::apache::config {
    # Realize virtual resources for Apache modules
    Webserver::Apache::Module <| |>

    # Realize virtual resources for enabling virtual hosts
    Webserver::Apache::Site <| |>
}

