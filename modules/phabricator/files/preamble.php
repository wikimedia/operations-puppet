<?php

// this is a test setup to prove the redirection code works as expected
// this should only respond to requests on the test subdomain
// phabzilla.wmflabs.org which is a proxy for phab-01
if ($_SERVER['HTTP_HOST'] == 'phabzilla.wmflabs.org') {
    $_SERVER['HTTP_HOST'] = 'bugs.wikimedia.org';
} else {
    // other hostnames are "NO-OP"
    return;
}

class redirector {
    protected $config;
    protected $mysqli;

    function __construct() {
        $this->config = json_decode(file_get_contents(__DIR__.'/redirect_config.json'));
        $this->mysqli = new mysqli(
            $this->config->mysql->host,
            $this->config->mysql->user,
            $this->config->mysql->pass,
            'phabricator_maniphest'
        );
        if ($this->mysqli->connect_error) {
           die('Connect Error (' . $this->mysqli->connect_errno . ') '
            . $this->mysqli->connect_error);
        }
    }
    public function redirect($url) {

        foreach ($this->config->urlPatterns as $i=>$p) {
            $matches = array();
            $pattern = '#'.$p->pattern.'#';

            if (preg_match( $pattern, $url, $matches )) {

                if (isset($p->fieldValue)) {
                    // dynamic redirect, look up $id using cross reference query
                    $fieldValue = str_replace('$1', $matches[1], $p->fieldValue);
                    $sql = $this->config->query;
                    $sql = str_replace('$fieldValue', $fieldValue, $sql);
                    $sql = str_replace('$fieldIndex', $this->config->fieldIndex, $sql);

                    if ($res = $this->mysqli->query($sql)) {
                        $res = $res->fetch_assoc();
                        // insert the cross referenced id into the redirectUrl
                        $redirect = str_replace('$id', $res['id'], $p->redirectUrl);
                        header("Location: $redirect");
                        echo "Redirecting to $redirect\n";
                        exit;
                    }
                } else {
                    // static redirect
                    header("Location: ". $p->redirectUrl);
                    exit;
                }
            }
        }
    }
}

$full_uri = $_SERVER['HTTP_HOST'].$_SERVER['REQUEST_URI'];
$r = new redirector();
$r->redirect($full_uri);
