-- These grants are wrong, as they lack passwords- do not use directly

-- cloudcontrol1005 - for maintaindbusers T331014
GRANT labsdbuser TO 'labsdbadmin'@'208.80.154.85' WITH ADMIN OPTION;
GRANT SUPER ON *.* TO 'labsdbadmin'@'208.80.154.85';
GRANT SELECT, INSERT, UPDATE ON `mysql`.* TO 'labsdbadmin'@'208.80.154.85';
GRANT SELECT, SHOW VIEW ON `%wik%`.* TO 'labsdbadmin'@'208.80.154.85';
GRANT SELECT, SHOW VIEW ON `%\\_p`.* TO 'labsdbadmin'@'208.80.154.85' WITH GRANT OPTION;

-- cloudcontrol1006 - for maintaindbusers T331014
GRANT labsdbuser TO 'labsdbadmin'@'208.80.154.149' WITH ADMIN OPTION;
GRANT SUPER ON *.* TO 'labsdbadmin'@'208.80.154.149';
GRANT SELECT, INSERT, UPDATE ON `mysql`.* TO 'labsdbadmin'@'208.80.154.149';
GRANT SELECT, SHOW VIEW ON `%wik%`.* TO 'labsdbadmin'@'208.80.154.149';
GRANT SELECT, SHOW VIEW ON `%\\_p`.* TO 'labsdbadmin'@'208.80.154.149' WITH GRANT OPTION;

-- cloudcontrol1007 - for maintaindbusers T331014
GRANT labsdbuser TO 'labsdbadmin'@'208.80.155.104' WITH ADMIN OPTION;
GRANT SUPER ON *.* TO 'labsdbadmin'@'208.80.155.104';
GRANT SELECT, INSERT, UPDATE ON `mysql`.* TO 'labsdbadmin'@'208.80.155.104';
GRANT SELECT, SHOW VIEW ON `%wik%`.* TO 'labsdbadmin'@'208.80.155.104';
GRANT SELECT, SHOW VIEW ON `%\\_p`.* TO 'labsdbadmin'@'208.80.155.104' WITH GRANT OPTION;

-- Labsdbuser is a role with privileges for all views like
-- GRANT SELECT, SHOW VIEW ON `rowikiquote\_p`.* TO 'labsdbuser'
CREATE ROLE labsdbuser;
GRANT USAGE ON *.* TO 'labsdbuser';
GRANT SELECT, SHOW VIEW ON `heartbeat_p`.* TO `labsdbuser`;
GRANT SELECT, SHOW VIEW ON `meta_p`.* TO `labsdbuser`;

-- maintainviews user used by cloud services team
GRANT ALL PRIVILEGES ON `heartbeat\\_p`.* TO 'maintainviews'@'localhost';
GRANT ALL PRIVILEGES ON `meta\\_p`.* TO 'maintainviews'@'localhost';
GRANT ALL PRIVILEGES ON `centralauth\\_p`.* TO 'maintainviews'@'localhost';
GRANT SELECT ON `centralauth`.* TO 'maintainviews'@'localhost';
GRANT SELECT ON `heartbeat`.* TO 'maintainviews'@'localhost';
GRANT ALL PRIVILEGES ON `%wik%\\_p`.* TO 'maintainviews'@'localhost';
GRANT ALL PRIVILEGES ON `%\\_p`.* TO 'maintainviews'@'localhost';
GRANT SELECT, DROP, CREATE VIEW ON `%wik%`.* TO 'maintainviews'@'localhost';
GRANT SELECT (user, host) ON `mysql`.`user` TO 'maintainviews'@'localhost';

-- maintainindexes user, used by cloud services team
GRANT SELECT, INDEX, ALTER ON `%wik%`.* TO 'maintainindexes'@'localhost';
GRANT SUPER ON *.* TO 'maintainindexes'@'localhost';

-- viewmaster user
GRANT SELECT ON *.* TO 'viewmaster'@'%';

-- quarry user granted 48 connections #T180141
GRANT USAGE ON *.* TO 's52788'@'%' WITH MAX_USER_CONNECTIONS 48;
-- user for wikiscan granted 15 connections T227462
GRANT USAGE ON *.* TO 'u12903'@'%' WITH MAX_USER_CONNECTIONS 15;
-- catscan2 (petscan) user granted 40 connections T255730
GRANT USAGE ON *.* TO 's51156'@'%' WITH MAX_USER_CONNECTIONS 40;
-- Analytics user granted 200 connections
GRANT USAGE ON *.* TO 's53272'@'%' WITH MAX_USER_CONNECTIONS 200;

-- wmf-pt-kill user has to be granted SUPER and SHOW PROCESSLIST and should be able to login via unix_socket (T203674)

GRANT PROCESS, SUPER ON *.* TO 'wmf-pt-kill'@'localhost' IDENTIFIED VIA unix_socket;

-- Currently only on the legacy wikireplicas for information gathering. T272723
-- Re-added on the new replicas T345211
GRANT PROCESS ON *.* TO 'querysampler'@'%';
