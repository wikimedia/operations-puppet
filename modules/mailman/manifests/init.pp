class mailman {
    include mailman::listserve
    include mailman::webui
    include mailman::scripts
}
