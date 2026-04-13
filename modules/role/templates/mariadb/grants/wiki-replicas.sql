-- These grants are incomplete, as they lack passwords- do not use directly

/*
 * Double escapes '\\_' should only be used if running these commands from a
 * bash shell using 'mysql -e COMMAND'. If running from a mysql shell, single
 * escapes '\_' must be used.
 */

-- cloudcontrol1006 - for maintaindbusers T331014
GRANT labsdbuser TO 'labsdbadmin'@'10.64.150.6' WITH ADMIN OPTION;
GRANT SUPER, CREATE USER ON *.* TO 'labsdbadmin'@'10.64.150.6' WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE ON `mysql`.* TO 'labsdbadmin'@'10.64.150.6';
GRANT SELECT, SHOW VIEW ON `%wik%`.* TO 'labsdbadmin'@'10.64.150.6';
GRANT SELECT, SHOW VIEW ON `%\\_p`.* TO 'labsdbadmin'@'10.64.150.6' WITH GRANT OPTION;

-- cloudcontrol1007 - for maintaindbusers T331014
CREATE USER 'labsdbadmin'@'10.64.148.21';
GRANT labsdbuser TO 'labsdbadmin'@'10.64.148.21' WITH ADMIN OPTION;
GRANT SUPER, CREATE USER ON *.* TO 'labsdbadmin'@'10.64.148.21' WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE ON `mysql`.* TO 'labsdbadmin'@'10.64.148.21';
GRANT SELECT, SHOW VIEW ON `%wik%`.* TO 'labsdbadmin'@'10.64.148.21';
GRANT SELECT, SHOW VIEW ON `%\\_p`.* TO 'labsdbadmin'@'10.64.148.21' WITH GRANT OPTION;

-- cloudcontrol1011 - for maintaindbusers T331014
CREATE USER 'labsdbadmin'@'10.64.151.8';
GRANT labsdbuser TO 'labsdbadmin'@'10.64.151.8' WITH ADMIN OPTION;
GRANT SUPER, CREATE USER ON *.* TO 'labsdbadmin'@'10.64.151.8' WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE ON `mysql`.* TO 'labsdbadmin'@'10.64.151.8';
GRANT SELECT, SHOW VIEW ON `%wik%`.* TO 'labsdbadmin'@'10.64.151.8';
GRANT SELECT, SHOW VIEW ON `%\\_p`.* TO 'labsdbadmin'@'10.64.151.8' WITH GRANT OPTION;


-- Labsdbuser is a role with privileges for all views like
-- GRANT SELECT, SHOW VIEW ON `rowikiquote\_p`.* TO 'labsdbuser'
CREATE ROLE labsdbuser;
GRANT USAGE ON *.* TO 'labsdbuser';
GRANT SELECT, SHOW VIEW ON `heartbeat_p`.* TO `labsdbuser`;
GRANT SELECT, SHOW VIEW ON `meta_p`.* TO `labsdbuser`;

-- maintainviews user used by cloud services team
GRANT SELECT ON `centralauth`.* TO 'maintainviews'@'localhost';
GRANT SELECT ON `heartbeat`.* TO 'maintainviews'@'localhost';
GRANT SELECT, DROP, CREATE VIEW, SHOW VIEW ON `%wik%`.* TO 'maintainviews'@'localhost';
GRANT SELECT (user, host) ON `mysql`.`user` TO 'maintainviews'@'localhost';
GRANT ALL PRIVILEGES ON `%\\_p`.* TO 'maintainviews'@'localhost';
GRANT ALL PRIVILEGES ON `%\\_maintain`.* TO 'maintainviews'@'localhost';

-- maintainindexes user, used by cloud services team
GRANT SELECT, INDEX, ALTER ON `%wik%`.* TO 'maintainindexes'@'localhost';
GRANT SUPER ON *.* TO 'maintainindexes'@'localhost';

-- viewmaster user
GRANT SELECT ON *.* TO 'viewmaster'@'%';

-- wmf-pt-kill user has to be granted SUPER and SHOW PROCESSLIST and should be able to login via unix_socket (T203674)

GRANT PROCESS, SUPER ON *.* TO 'wmf-pt-kill'@'localhost' IDENTIFIED VIA unix_socket;

-- HAProxy health checks
-- haproxy@cloudlb1001.eqiad.wmnet
GRANT USAGE ON *.* TO 'haproxy'@'10.64.151.2';
-- haproxy@cloudlb1002.eqiad.wmnet
GRANT USAGE ON *.* TO 'haproxy'@'10.64.150.4';

-- Currently only on the legacy wikireplicas for information gathering. T272723
-- Re-added on the new replicas T345211
GRANT PROCESS ON *.* TO 'querysampler'@'%';
