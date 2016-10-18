require 'spec_helper'

describe 'service::node', :type => :define do

  let(:title) { 'my_service_name' }
  let(:param) { { :port => 1234 } }

  it { is_expected.to compile }
end