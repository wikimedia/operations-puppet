# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'netbase::services' do
  it { is_expected.to run }
  it 'test single service as string' do
    is_expected.to run.with_params('ssh')
      .and_return({"ssh" => {"protocols" => ["tcp"], "port" => 22, "description" => "SSH Remote Login Protocol"}})
  end
  it 'test single service as array' do
    is_expected.to run.with_params(['ssh'])
      .and_return({"ssh" => {"protocols" => ["tcp"], "port" => 22, "description" => "SSH Remote Login Protocol"}})
  end
  it 'test entry with multiple protocols' do
    is_expected.to run.with_params(['domain'])
      .and_return({"domain" => {"protocols" => ["tcp", "udp"], "port" => 53, "description" => "Domain Name Server"}})
  end
  it 'test multiple args' do
    is_expected.to run.with_params(['ssh', 'domain'])
      .and_return({
        "ssh" => {"protocols" => ["tcp"], "port" => 22, "description" => "SSH Remote Login Protocol"},
        "domain" => {"protocols" => ["tcp", "udp"], "port" => 53, "description" => "Domain Name Server"}})
  end
  it 'test aliases' do
    is_expected.to run.with_params(['kerberos-sec'])
      .and_return({
        "kerberos" => {
          "protocols" => ["tcp", "udp"],
          "port" => 88,
          "description" => "Kerberos v5",
          "aliases" => ["kerberos5", "krb5", "kerberos-sec"]
        }
      })
  end
end
