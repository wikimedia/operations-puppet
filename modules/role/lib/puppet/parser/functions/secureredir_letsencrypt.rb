module Puppet::Parser::Functions
  newfunction(:secureredir_letsencrypt, :type => :rvalue, :arity => 1) do |args|
    cert_groups = {}
    CERT_GROUP_LIMIT = 100
    # chunk args[0] by CERT_GROUP_LIMIT
    i = 0
    while args[0][i..i + CERT_GROUP_LIMIT - 1]
      certs = args[0][i..i + CERT_GROUP_LIMIT - 1]
      if certs && certs.length > 0
        id = i / CERT_GROUP_LIMIT
        cert_groups["secureredir_#{id}"] = {
          'subjects'      => certs.join(','),
          'puppet_svc'    => 'nginx',
          'system_svc'    => 'nginx'
        }
      else
        break # done
      end
      i += CERT_GROUP_LIMIT
    end
    return cert_groups
  end
end
