require 'spec_helper'

describe 'postfix::flatten_hosts' do
  it { is_expected.to run.with_params(['2001:db8::1', '192.0.2.1']).and_return(['[2001:db8::1]', '192.0.2.1']) }
  it { is_expected.to run.with_params([['2001:db8::1', 389], ['192.0.2.1', 389]]).and_return(['[2001:db8::1]:389', '192.0.2.1:389']) }
  it { is_expected.to run.with_params(:undef).and_return(nil) }
  it { is_expected.to run.with_params(nil).and_return(nil) }
  it { expect { is_expected.to run.with_params('invalid') }.to raise_error(%r{parameter 'hosts' }) }
  it { expect { is_expected.to run.with_params([true]) }.to raise_error(%r{parameter 'hosts' }) }
end
