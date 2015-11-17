# Deprecated older role that no longer works
class role::lamp::labs {

    include role::labs-mysql-server
    include ::apache
    include ::apache::mod::php5
    require_package('php5-mysql')
    require_package('php5-cli')

}
