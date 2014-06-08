#  Installs basic LAMP services on an instance:
#
#  - Apache
#  - Mysql
#  - PHP5
# 
#  The root mysql password is empty to start.  You should
#  change it!
class role::lamp::labs {

    include role::labs-mysql-server
    include webserver::php5-mysql
    include webserver::php5
}
