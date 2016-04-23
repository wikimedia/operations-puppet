CREATE TABLE prefix (
    id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    project VARCHAR(64) BINARY NOT NULL, -- 63 dns label length limit
    prefix VARCHAR(64) BINARY NOT NULL -- 63 dns label length limit + 1 for trailing .
);
CREATE UNIQUE INDEX project_prefix ON prefix(project, prefix);

CREATE TABLE roleassignment(
    id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    prefix_id INT UNSIGNED NOT NULL,
    role VARCHAR(255) BINARY NOT NULL
);

CREATE TABLE hieraassignment(
    id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    prefix_id INT UNSIGNED NOT NULL,
    hiera_data TEXT NOT NULL
);
CREATE UNIQUE INDEX hiera_prefix ON hieraassignment(prefix_id);
