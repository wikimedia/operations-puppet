# SPDX-License-Identifier: Apache-2.0
#
# This class generates a certificate to be used within the fr-tech environment
# (which is separate from production). The certificate is manually synced and
# deployed in the fr-tech setup
class profile::frtech::kafka_certificate() {

    $cert_target_directory = '/etc/fr-tech-kafka-client'

    file { $cert_target_directory:
        ensure => directory,
        mode   => '0444',
    }

    profile::pki::get_cert('kafka', 'kafka_fundraising_client', {
        'outdir'  => $cert_target_directory,
        'owner'   => 'fr-tech-admins',
        'group'   => 'fr-tech-admins',
        'profile' => 'kafka_11',
    })
}
