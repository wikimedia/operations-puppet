# sets up Apache for a planet-venus setup
class planet::webserver {

    class { 'webserver::php5': }
    include ::apache::mod::rewrite
    # so we can vary on X-Forwarded-Proto when behind misc-web
    include ::apache::mod::headers

    # dependencies for webserver setup
    Class['webserver::php5'] ->
    Class['::apache::mod::rewrite'] ->
    Class['::apache::mod::headers']

}
