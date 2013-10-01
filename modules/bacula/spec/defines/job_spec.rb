require 'spec_helper'

describe 'bacula::client::job', :type => :define do
    let(:title) { 'something' }
    let(:params) { {
        :fileset      => 'root',
        :jobdefaults  => 'testdefaults',
        }
    }
end
