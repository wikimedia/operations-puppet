# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'query_service::get_federated_endpoint_hostnames' do
  it { is_expected.to run.with_params(nil).and_return(nil) }
  it { is_expected.to run.with_params({}).and_return(nil) }
  it { is_expected.to run.with_params({"https://internal" => ["https://visible"]}).and_return("internal") }
  it { is_expected.to run.with_params({"https://internal:8080" => ["https://visible"]}).and_return("internal") }
  it { is_expected.to run.with_params({"https://internal/sparql" => ["https://visible"]}).and_return("internal") }
  it { is_expected.to run.with_params({"https://internal:8080/sparql" => ["https://visible"]}).and_return("internal") }
  it { is_expected.to run.with_params(
    {"https://internal/sparql" => ["https://visible"], "https://internal2/sparql" => ["https://visible2"]}
  ).and_return("internal,internal2") }
  it { is_expected.to run.with_params({"https:///" => ["https://visible"]}).and_raise_error(Puppet::ParseError, /Unparseable URL/) }
end
