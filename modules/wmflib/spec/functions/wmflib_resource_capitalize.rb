# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

describe 'wmflib::resource::capitalize' do
  it { is_expected.to run.with_params('foo').and_return('Foo') }
  it { is_expected.to run.with_params('foo::bar').and_return('Foo::Bar') }
  it { is_expected.to run.with_params('foo::bar::stuff').and_return('Foo::Bar::Stuff') }
  it { is_expected.to run.with_params('FOO::BAR::STUFF').and_return('Foo::Bar::Stuff') }
  it { is_expected.to run.with_params('Foo::Bar::STUFf').and_return('Foo::Bar::Stuff') }
  it { is_expected.to run.with_params('fOO::bAR::stufF').and_return('Foo::Bar::Stuff') }
  it { is_expected.to run.with_params('foo:bar').and_raise_error ArgumentError }
  it { is_expected.to run.with_params('foo:bar:stuff').and_raise_error ArgumentError }
  it { is_expected.to run.with_params(':foo').and_raise_error ArgumentError }
  it { is_expected.to run.with_params('foo:').and_raise_error ArgumentError }
  it { is_expected.to run.with_params('foo::').and_raise_error ArgumentError }
  it { is_expected.to run.with_params('::foo').and_raise_error ArgumentError }
end
