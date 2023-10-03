# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'wmflib::get_clusters' do
  describe 'one fact' do
    let(:pre_condition) do
      "function wmflib::puppetdb_query($pql) {
        [
          {
            'certname' => 'misc1.eqiad',
            'parameters' => {
              'cluster' => 'misc',
              'site'    => 'eqiad'
            }
          },
          {
            'certname' => 'misc2.eqiad',
            'parameters' => {
              'cluster' => 'misc',
              'site'    => 'eqiad'
            }
          },
          {
            'certname' => 'misc1.codfw',
            'parameters' => {
              'cluster' => 'misc',
              'site'    => 'codfw'
            }
          },
          {
            'certname' => 'misc2.codfw',
            'parameters' => {
              'cluster' => 'misc',
              'site'    => 'codfw'
            }
          },
          {
            'certname' => 'lvs1.eqiad',
            'parameters' => {
              'cluster' => 'lvs',
              'site'    => 'eqiad'
            }
          },
          {
            'certname' => 'lvs1.codfw',
            'parameters' => {
              'cluster' => 'lvs',
              'site'    => 'codfw'
            }
          }
        ]
      }"
    end
    it do
      is_expected.to run.with_params.and_return({
        'misc' => {
          'eqiad' => ['misc1.eqiad', 'misc2.eqiad'],
          'codfw' => ['misc1.codfw', 'misc2.codfw']
        },
        'lvs' => {
          'eqiad' => ['lvs1.eqiad'],
          'codfw' => ['lvs1.codfw']
        }
      })
    end
    it do
      is_expected.to run.with_params("site" => ["eqiad"]).and_return({
        'misc' => {
          'eqiad' => ['misc1.eqiad', 'misc2.eqiad'],
        },
        'lvs' => {
          'eqiad' => ['lvs1.eqiad'],
        }
      })
    end
    it do
      is_expected.to run.with_params("cluster" => ['lvs']).and_return({
        'lvs' => {
          'eqiad' => ['lvs1.eqiad'],
          'codfw' => ['lvs1.codfw']
        }
      })
    end
  end
end
