# Return the base configuration directory for a specific php version.
function php::config_dir(String $version) >> String {
    return "/etc/php/${version}"
}
