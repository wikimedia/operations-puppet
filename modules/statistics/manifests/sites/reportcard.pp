# reportcard.wikimedia.org
class statistics::sites::reportcard {
    require statistics::webserver
    misc::limn::instance { 'reportcard': }
}

