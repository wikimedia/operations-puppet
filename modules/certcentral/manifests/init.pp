# Handles basic requirements for certcentral clients:
#  - Deploy of LE intermediate certificates

class certcentral {
    # LE Intermediate: current since ~2016-03-26
    if !defined(Sslcert::Ca['Lets_Encrypt_Authority_X3']) {
        sslcert::ca { 'Lets_Encrypt_Authority_X3':
            source  => 'puppet:///modules/certcentral/lets-encrypt-x3-cross-signed.pem'
        }
    }

    # LE Intermediate: disaster recovery fallback since ~2016-03-26
    if !defined(Sslcert::Ca['Lets_Encrypt_Authority_X4']) {
        sslcert::ca { 'Lets_Encrypt_Authority_X4':
            source  => 'puppet:///modules/certcentral/lets-encrypt-x4-cross-signed.pem'
        }
    }
}
