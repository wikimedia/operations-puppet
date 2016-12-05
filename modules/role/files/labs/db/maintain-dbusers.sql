-- Keep state about tool / user accounts on tool labs and their mysql
-- account counterparts. This is the canonical store of this information.
-- Schema is set up to be able to trivially query the following things:
--  1. What labsdb hosts does this tool / user *not* have an account on.
--  2. What's the mysql username / password for this tool / user.
CREATE TABLE accounts(
    id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    mysql_username VARCHAR(255) NOT NULL,
    type enum('tool', 'user') NOT NULL,
    username VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
) CHARSET=utf8mb4;
CREATE UNIQUE INDEX account_type ON accounts(type, username);

CREATE TABLE account_hosts(
    id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    account_id INT UNSIGNED NOT NULL,
    hostname VARCHAR(255) NOT NULL,
) CHARSET=utf8mb4;
CREATE INDEX account_host_status ON accounts(account_id, hostname);
