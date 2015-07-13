# = Class: icinga::nsca::firewall
#
# Sets up firewall rules to allow NSCA traffic on port 5667
class icinga::nsca::firewall {

    # NSCA on port 5667
    ferm::rule { 'ncsa_allowed':
        rule => 'saddr (127.0.0.1 \
          $CODFW_PRIVATE_PUBLIC_FRACK_CODFW \
          $CODFW_PUBLIC_PUBLIC_FRACK_CODFW \
          $EQIAD_PRIVATE_ANALYTICS1_A_EQIAD \
          $EQIAD_PRIVATE_ANALYTICS1_B_EQIAD \
          $EQIAD_PRIVATE_ANALYTICS1_C_EQIAD \
          $EQIAD_PRIVATE_ANALYTICS1_D_EQIAD \
          $EQIAD_PRIVATE_LABS_HOSTS1_A_EQIAD \
          $EQIAD_PRIVATE_LABS_HOSTS1_B_EQIAD \
          $EQIAD_PRIVATE_LABS_HOSTS1_D_EQIAD \
          $EQIAD_PRIVATE_LABS_SUPPORT1_C_EQIAD \
          $EQIAD_PRIVATE_PRIVATE1_A_EQIAD \
          $EQIAD_PRIVATE_PRIVATE1_B_EQIAD \
          $EQIAD_PRIVATE_PRIVATE1_C_EQIAD \
          $EQIAD_PRIVATE_PRIVATE1_D_EQIAD \
          $EQIAD_PRIVATE_PRIVATE_FRACK_EQIAD \
          $EQIAD_PUBLIC_PUBLIC1_A_EQIAD \
          $EQIAD_PUBLIC_PUBLIC1_B_EQIAD \
          $EQIAD_PUBLIC_PUBLIC1_C_EQIAD \
          $EQIAD_PUBLIC_PUBLIC1_D_EQIAD \
          $EQIAD_PUBLIC_PUBLIC_FRACK_EQIAD \
          $ESAMS_PRIVATE_PRIVATE1_ESAMS \
          $ESAMS_PUBLIC_PUBLIC1_ESAMS \
          $ULSFO_PRIVATE_PRIVATE1_ULSFO \
          $ULSFO_PUBLIC_PUBLIC1_ULSFO \
          proto tcp dport 5667 ACCEPT;'
    }
}
