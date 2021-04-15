# @summary Ensure certificate is created and return a hash of the relevant paths
# @param label the CA label to use 
# @param label The cfssl CA label to use, this take precedent to over additional_params['label']
# @param A common name to use for the certificate, this take precedent to over additional_params['common_name']
# @param additional_params a hash of additional parameters to pass to cfssl::cert.
function profile::pki::get_cert(
  String $label,
  String $common_name       = $facts['networking']['fqdn'],
  Hash   $additional_params = {},
) >> Hash {
  # need this to access:
  # $profile::pki::client::ensure
  # and profile::pli::client -> cfssl::client -> cfssl
  # $cfssl::ssl_dir
  include profile::pki::client
  unless $profile::pki::client::ensure == 'present' {
    fail('profile::pki::client::ensure must be present to use this function')
  }
  $safe_title = "${label}__${common_name}".regsubst('[^\w\-]', '_', 'G')
  ensure_resource('cfssl::cert', $safe_title, $additional_params + {
    'common_name' => $common_name,
    'label'       => $label,
  })
  $outdir = $additional_params['outdir'] ? {
    undef   => "${cfssl::ssl_dir}/${safe_title}",
    default => $additional_params['outdir'],
  }
  $paths = {
    'cert' => "${outdir}/${safe_title}.pem",
    'key' => "${outdir}/${safe_title}-key.pem",
  }
  pick($additional_params['provide_chain'], false) ? {
    true    => {'ca' => "${outdir}/${label}_chain.pem"} + $paths,
    default => $paths,
  }
}
