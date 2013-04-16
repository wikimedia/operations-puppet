#  Installs basic LAMP services on an instance:
#
#  - Apache
#  - Mysql
#  - PHP5
# 
#  The root mysql password is empty to start.  You should
#  change it!
class role::labs-lamp {

    include "role::labs-mysql-server", "webserver::php5-mysql"
}
