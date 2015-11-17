# sets up Apache for a planet-venus setup
class planet::webserver {
    include ::apache
    include ::apache::mod::rewrite
    # so we can vary on X-Forwarded-Proto when behind misc-web
    include ::apache::mod::headers
    include ::apache::mod::php5
}
