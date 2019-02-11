# Handles basic requirements for acme-chief clients:
#  - Deploy of LE intermediate certificates

class acme_chief {
    # LE Intermediate: current since ~2016-03-26
    if !defined(Sslcert::Ca['Lets_Encrypt_Authority_X3']) {
        sslcert::ca { 'Lets_Encrypt_Authority_X3':
            source  => 'puppet:///modules/acme_chief/lets-encrypt-x3-cross-signed.pem'
        }
    }

    # LE Intermediate: disaster recovery fallback since ~2016-03-26
    if !defined(Sslcert::Ca['Lets_Encrypt_Authority_X4']) {
        sslcert::ca { 'Lets_Encrypt_Authority_X4':
            source  => 'puppet:///modules/acme_chief/lets-encrypt-x4-cross-signed.pem'
        }
    }
}
