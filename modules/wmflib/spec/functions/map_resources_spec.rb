require 'spec_helper'
require 'mocha/test_unit'

describe 'map_resources' do


  describe "when called with a single title on an existing resource" do
    let :pre_condition do
      'file { "/etc/foobar": ensure => present}'
    end
    it do
      should run.with_params('file', '/etc/foobar', {'ensure' => 'present'})
      expect(compiler.catalog.resource('File[/etc/foobar]').to_s).to eq('File[/etc/foobar]')
    end
  end

  describe "when called with multiple titles with interpolated parameters" do
    let :pre_condition do
      'file { "/etc/foobar": ensure => present, content => "Include /etc/foobar"}'
    end
    it do
      should run.with_params('file', ['/etc/foobar', '/etc/flannel'], {'ensure' => 'present', 'content' => 'Include @@title@@'})
      puts compiler.catalog.resource('File[/etc/flannel]').inspect
      expect(compiler.catalog.resource('File[/etc/flannel]')[:content]).to eq("Include /etc/flannel")

      # This should raise an error instead
      should run.with_params('file', ['/etc/foobar', '/etc/flannel'], {'ensure' => 'absent'}).and_raise_error(Puppet::Error)
    end
  end
end
