-- SPDX-License-Identifier: Apache-2.0
CREATE TABLE topics (`channel` VARCHAR(256) PRIMARY KEY, `topic` TEXT);
CREATE TABLE acls (`command` VARCHAR(256), `identifier` VARCHAR(256), PRIMARY KEY (`command`, `identifier`));
