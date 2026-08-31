CREATE TABLE project (
    project_id INTEGER UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    project_name VARCHAR(255) NOT NULL,
    project_openstack_id VARCHAR(255) NOT NULL,
    UNIQUE INDEX u_project_name (project_name),
    UNIQUE INDEX u_project_openstack_id (project_openstack_id)
) CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE prefix (
    id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    prefix_project_id INTEGER UNSIGNED NOT NULL,
    prefix VARCHAR(255) NOT NULL, -- 253 dns fqdn length limit + 1 for trailing .
    FOREIGN KEY f_project_prefix (prefix_project_id) REFERENCES project (project_id) ON DELETE CASCADE,
    UNIQUE INDEX u_project_id_prefix (prefix_project_id, prefix)
) CHARSET=utf8mb4;
CREATE UNIQUE INDEX project_prefix ON prefix(project, prefix);

CREATE TABLE roleassignment(
    id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    prefix_id INT UNSIGNED NOT NULL,
    role VARCHAR(255) NOT NULL,
    FOREIGN KEY f_roleassignment_prefix_id (prefix_id) REFERENCES prefix (id) ON DELETE CASCADE
) CHARSET=utf8mb4;

CREATE TABLE hieraassignment(
    id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    prefix_id INT UNSIGNED NOT NULL,
    hiera_data MEDIUMTEXT NOT NULL,
    FOREIGN KEY f_hieraassignment_prefix_id (prefix_id) REFERENCES prefix (id) ON DELETE CASCADE
) CHARSET=utf8mb4;
CREATE UNIQUE INDEX hiera_prefix ON hieraassignment(prefix_id);

CREATE TABLE git_update_queue_commit (
    guqc_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    guqc_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    guqc_author_user VARCHAR(255) NOT NULL,
    guqc_commit_message TEXT NOT NULL
) CHARSET=utf8mb4;

CREATE TABLE git_update_queue_file (
    guqf_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    guqf_commit INT UNSIGNED NOT NULL,
    guqf_file_path VARCHAR(511) NOT NULL,
    guqf_new_content MEDIUMTEXT,
    FOREIGN KEY f_guqf_commit (guqf_commit) REFERENCES git_update_queue_commit (guqc_id) ON DELETE CASCADE
) CHARSET=utf8mb4;
