# hosts that use letsencrypt certs
class role::sslcert::letsencrypt {

    include sslcert::letsencrypt::simple
}
