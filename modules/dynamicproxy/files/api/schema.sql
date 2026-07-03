-- SPDX-License-Identifier: Apache-2.0

CREATE TABLE project (
	id INTEGER UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
	openstack_id VARCHAR(256) NOT NULL,
	UNIQUE INDEX u_project_openstack_id (openstack_id)
) CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE route (
	id INTEGER UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
	domain VARCHAR(256) NOT NULL,
	project_id INTEGER UNSIGNED NOT NULL,
	backend_url VARCHAR(256) NOT NULL,
	UNIQUE INDEX u_route_domain (domain),
	FOREIGN KEY f_route_project (project_id) REFERENCES project (id) ON DELETE CASCADE
) CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
