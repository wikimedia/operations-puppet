#!/usr/bin/python3

import transfer
import mysqladmin

def main():
    db2001 = mysqladmin.server(host = 'db2001.codfw.wmnet')
    db2002 = mysqladmin.server(host = 'db2002.codfw.wmnet')
    db2001.depool()
    db2002.depool()
    db2001.shutdown()
    db2002.shutdown()
    clone_db(db2001, db2002)
    db2001.start()
    db2002.start()
    db2001.pool()
    db2002.pool()


if __name__ == "__main__":
    main()
