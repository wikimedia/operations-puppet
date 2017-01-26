class mailman {
    include ::mailman::listserve
    include ::mailman::webui
    include ::mailman::scripts
    include ::mailman::cron
}
