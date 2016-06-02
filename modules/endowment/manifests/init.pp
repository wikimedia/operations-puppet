# sets up https://endowment.wikimedia.org/ (T136735)
class endowment {

    include ::apache
    include ::apache::mod::headers

    apache::site { 'endowment.wikimedia.org':
        source => 'puppet:///modules/endowment/endowment.wikimedia.org',
    }

   # git::clone { 'wikimedia/endowment':
   #     ensure    => 'latest',
   #     directory => '/srv/org/wikimedia/endowment',
   #     branch    => 'master',
   # }
}
