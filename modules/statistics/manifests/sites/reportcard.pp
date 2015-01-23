# == Class statistics::sites::reportcard
class statistics::sites::reportcard {
    Class['::statistics::web'] -> Class['::statistics::sites::datasets']

    misc::limn::instance { 'reportcard': }
}

