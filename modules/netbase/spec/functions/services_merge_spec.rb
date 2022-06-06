# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'
services_default = {
  'ssh' => {
    'protocols' => ['tcp'],
    'port' => 22,
    'description' => 'SSH Remote Login Protocol'
  },
  'domain' => {
    'protocols' => ['tcp', 'udp'],
    'port' => 53,
    'description' => 'Domain Name Server'
  },
  'kerberos' => {
    'protocols' => ['tcp', 'udp'],
    'port' => 88,
    'description' => 'Kerberos v5',
    'aliases' => ['kerberos5', 'krb5', 'kerberos-sec']
  },
  'traceroute' => {
    'protocols' => ['udp'],
    'port' => 33_434,
    'portend' => 33_534,
  }
}
services_user = {
  'putty' => {
    'protocols' => ['tcp'],
    'port' => 22,
    'description' => 'SSH Remote Login Protocol'
  },
  'tcpmux' => {
    'protocols' => ['tcp'],
    'port' => 1,
  }
}
services_out_user = {
  'putty' => {
    'protocols' => ['tcp'],
    'port' => 22,
    'description' => 'SSH Remote Login Protocol'
  },
  'domain' => {
    'protocols' => ['tcp', 'udp'],
    'port' => 53,
    'description' => 'Domain Name Server'
  },
  'kerberos' => {
    'protocols' => ['tcp', 'udp'],
    'port' => 88,
    'description' => 'Kerberos v5',
    'aliases' => ['kerberos5', 'krb5', 'kerberos-sec']
  },
  'tcpmux' => {
    'protocols' => ['tcp'],
    'port' => 1,
  },
  'traceroute' => {
    'protocols' => ['udp'],
    'port' => 33_434,
    'portend' => 33_534,
  }
}
services_out_default = {
  'ssh' => {
    'protocols' => ['tcp'],
    'port' => 22,
    'description' => 'SSH Remote Login Protocol'
  },
  'domain' => {
    'protocols' => ['tcp', 'udp'],
    'port' => 53,
    'description' => 'Domain Name Server'
  },
  'kerberos' => {
    'protocols' => ['tcp', 'udp'],
    'port' => 88,
    'description' => 'Kerberos v5',
    'aliases' => ['kerberos5', 'krb5', 'kerberos-sec']
  },
  'tcpmux' => {
    'protocols' => ['tcp'],
    'port' => 1,
  },
  'traceroute' => {
    'protocols' => ['udp'],
    'port' => 33_434,
    'portend' => 33_534,
  }
}
services_out_user_aliases = {
  'putty' => {
    'protocols' => ['tcp'],
    'port' => 22,
    'description' => 'SSH Remote Login Protocol',
    'aliases' => ['ssh']
  },
  'domain' => {
    'protocols' => ['tcp', 'udp'],
    'port' => 53,
    'description' => 'Domain Name Server'
  },
  'kerberos' => {
    'protocols' => ['tcp', 'udp'],
    'port' => 88,
    'description' => 'Kerberos v5',
    'aliases' => ['kerberos5', 'krb5', 'kerberos-sec']
  },
  'tcpmux' => {
    'protocols' => ['tcp'],
    'port' => 1,
  },
  'traceroute' => {
    'protocols' => ['udp'],
    'port' => 33_434,
    'portend' => 33_534,
  }
}
services_out_default_aliases = {
  'ssh' => {
    'protocols' => ['tcp'],
    'port' => 22,
    'description' => 'SSH Remote Login Protocol',
    'aliases' => ['putty']
  },
  'domain' => {
    'protocols' => ['tcp', 'udp'],
    'port' => 53,
    'description' => 'Domain Name Server'
  },
  'kerberos' => {
    'protocols' => ['tcp', 'udp'],
    'port' => 88,
    'description' => 'Kerberos v5',
    'aliases' => ['kerberos5', 'krb5', 'kerberos-sec']
  },
  'tcpmux' => {
    'protocols' => ['tcp'],
    'port' => 1,
  },
  'traceroute' => {
    'protocols' => ['udp'],
    'port' => 33_434,
    'portend' => 33_534,
  }
}
services_should_win = {
  'domain' => {
    'protocols' => ['tcp', 'udp'],
    'port' => 53,
    'description' => 'Domain Name Server'
  }
}
services_should_loose = {
  'dns' => {
    'protocols' => ['udp'],
    'port' => 53,
    'description' => 'Domain Name Server'
  }
}
services_should_win_aliases = {
  'domain' => {
    'protocols' => ['tcp', 'udp'],
    'port' => 53,
    'description' => 'Domain Name Server',
    'aliases' => ['dns']
  }
}
describe 'netbase::services::merge' do
  it { is_expected.to run.with_params(services_default, services_user).and_return(services_out_user) }
  it { is_expected.to run.with_params(services_user, services_default).and_return(services_out_default) }
  it { is_expected.to run.with_params(services_default, services_user, true).and_return(services_out_user_aliases) }
  it { is_expected.to run.with_params(services_user, services_default, true).and_return(services_out_default_aliases) }
  # with a loose match we expect should win
  it do
    is_expected.to run.with_params(services_should_loose, services_should_win, false, false)
      .and_return(services_should_win)
  end
  it do
    is_expected.to run.with_params(services_should_loose, services_should_win, true, false)
      .and_return(services_should_win_aliases)
  end
  # with a strict match we expect two elements
  it do
    is_expected.to run.with_params(services_should_loose, services_should_win, true)
      .and_return(services_should_win.merge(services_should_loose))
  end
end
