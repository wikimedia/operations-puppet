-- Keep state about tool / user accounts on tool labs and their mysql
-- account counterparts. This is the canonical store of this information.
-- Schema is set up to be able to trivially query the following things:
--  1. What labsdb hosts does this tool / user *not* have an account on.
--  2. What's the mysql username / password for this tool / user.
CREATE TABLE account(
    id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    mysql_username VARCHAR(255) NOT NULL,
    type enum('tool', 'user') NOT NULL,
    username VARCHAR(255) NOT NULL,
    password_hash BINARY(41) NOT NULL -- MySQL password hash format
  ) ENGINE=InnoDB ROW_FORMAT=Dynamic CHARSET=utf8mb4;
CREATE UNIQUE INDEX account_type ON account(type, username);

CREATE TABLE account_host(
    id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    account_id INT UNSIGNED NOT NULL,
    hostname VARCHAR(255) NOT NULL,
    status enum('present', 'absent') NOT NULL
) ENGINE=InnoDB ROW_FORMAT=Dynamic CHARSET=utf8mb4;
-- We need to ensure that there's no two entries for same host / account combo
CREATE UNIQUE INDEX account_host(account_id, hostname);
