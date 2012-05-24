#include "mysql.db"

class role::labsdb {
        class { "generic::mysql::server":
                  datadir => "/mnt"
              }
}
