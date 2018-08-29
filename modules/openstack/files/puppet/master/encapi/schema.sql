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
