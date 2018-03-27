-- Initial grants and grants added at T178128
GRANT labsdbuser TO 'labsdbadmin'@'10.64.37.19' WITH ADMIN OPTION
GRANT SELECT, INSERT, UPDATE ON `mysql`.* TO 'labsdbadmin'@'10.64.37.19'
GRANT SELECT, SHOW VIEW ON `%\\_p`.* TO 'labsdbadmin'@'10.64.37.19' WITH GRANT OPTION
GRANT SELECT, SHOW VIEW ON `%wik%`.* TO 'labsdbadmin'@'10.64.37.19'

GRANT labsdbuser TO 'labsdbadmin'@'10.64.37.20' WITH ADMIN OPTION
GRANT SELECT, INSERT, UPDATE ON `mysql`.* TO 'labsdbadmin'@'10.64.37.20'
GRANT SELECT, SHOW VIEW ON `%wik%`.* TO 'labsdbadmin'@'10.64.37.20'
GRANT SELECT, SHOW VIEW ON `%\\_p`.* TO 'labsdbadmin'@'10.64.37.20' WITH GRANT OPTION

-- Labsdbuser is a role with privileges for all views like
-- GRANT SELECT, SHOW VIEW ON `rowikiquote\_p`.* TO 'labsdbuser'
GRANT USAGE ON *.* TO 'labsdbuser'

-- maintainviews user used by cloud services team
GRANT ALL PRIVILEGES ON `heartbeat\\_p`.* TO 'maintainviews'@'localhost'
GRANT ALL PRIVILEGES ON `meta\\_p`.* TO 'maintainviews'@'localhost'
GRANT ALL PRIVILEGES ON `centralauth\\_p`.* TO 'maintainviews'@'localhost'
GRANT SELECT ON `centralauth`.* TO 'maintainviews'@'localhost'
GRANT SELECT ON `heartbeat`.* TO 'maintainviews'@'localhost'
GRANT ALL PRIVILEGES ON `%wik%\\_p`.* TO 'maintainviews'@'localhost'
GRANT ALL PRIVILEGES ON `%\\_p`.* TO 'maintainviews'@'localhost'
GRANT SELECT, DROP, CREATE VIEW ON `%wik%`.* TO 'maintainviews'@'localhost'
GRANT SELECT (user, host) ON `mysql`.`user` TO 'maintainviews'@'localhost'

-- maintainindexes user, used by cloud services team
GRANT SELECT, INDEX, ALTER ON `%wik%`.* TO 'maintainindexes'@'localhost';

-- viewmaster user
GRANT SELECT ON *.* TO 'viewmaster'@'%'

-- quarry user granted 48 connections #T180141
GRANT USAGE ON *.* TO 's52788'@'%' WITH MAX_USER_CONNECTIONS 48;
