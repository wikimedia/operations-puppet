CREATE TABLE prefix (
    id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    project VARCHAR(64) NOT NULL, -- 63 dns label length limit
    prefix VARCHAR(255) NOT NULL -- 253 dns fqdn length limit + 1 for trailing .
) CHARSET=utf8mb4;
CREATE UNIQUE INDEX project_prefix ON prefix(project, prefix);

CREATE TABLE roleassignment(
    id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    prefix_id INT UNSIGNED NOT NULL,
    role VARCHAR(255) NOT NULL
) CHARSET=utf8mb4;

CREATE TABLE hieraassignment(
    id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    prefix_id INT UNSIGNED NOT NULL,
    hiera_data TEXT NOT NULL
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
    guqf_new_content TEXT,
    FOREIGN KEY f_guqf_commit (guqf_commit) REFERENCES git_update_queue_commit (guqc_id) ON DELETE CASCADE
) CHARSET=utf8mb4;
