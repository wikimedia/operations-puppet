# definition of an ishmael config

define ishmael::config(
    $db_central_host = 'db1001.eqiad.wmnet',
    $review_table    = '%query_review',
    $history_table   = '%query_review_history',
) {

    include passwords::mysql::querydigest

    file { $title:
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('ishmael/conf.php.erb');
      }
}

