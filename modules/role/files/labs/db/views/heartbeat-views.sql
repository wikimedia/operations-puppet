-- TODO: add it to maintain-replicas
-- This only has to be run once per host
-- And there is no checks that the underlying tables exist
CREATE DATABASE IF NOT EXISTS `heartbeat_p`;
CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER=`root`@`localhost`
SQL SECURITY DEFINER VIEW
`heartbeat_p`.`heartbeat` AS
SELECT
`shard` AS `shard`,
max(`heartbeat`.`heartbeat`.`ts`) AS `last_updated`,
timestampdiff(SECOND, max(`heartbeat`.`heartbeat`.`ts`), utc_timestamp()) AS `lag`
FROM `heartbeat`.`heartbeat`
GROUP BY `shard`;
-- Change SECOND precission to MICROSECOND when this bug disappears:
-- https://mariadb.atlassian.net/browse/MDEV-9175
