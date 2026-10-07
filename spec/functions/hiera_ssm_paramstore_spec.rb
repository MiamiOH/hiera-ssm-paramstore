# frozen_string_literal: true

require 'spec_helper'
require 'aws-sdk-ssm'

describe 'hiera_ssm_paramstore' do
  let(:context) { Puppet::Pops::Lookup::Context.new('m', 'm') }
  let(:ssm_client) { instance_double(Aws::SSM::Client) }

  before(:each) do
    allow(Aws::SSM::Client).to receive(:new).and_return(ssm_client)

    allow(context).to receive(:cache_has_key).and_return(false)
    allow(context).to receive(:explain)
    allow(context).to receive(:interpolate) { |value| value }
    allow(context).to receive(:cache)
    allow(context).to receive(:not_found)
  end

  describe 'lookup_key' do
    context 'when fetching a single key' do
      let(:options) do
        {
          'uri' => '/',
          'region' => 'us-east-1',
          'get_all' => false,
        }
      end

      it 'finds a string' do
        expect(context).to receive(:interpolate)
          .with('/plain')
          .and_return('/plain')

        param_double = instance_double(Aws::SSM::Types::Parameter, value: 'value_plain')
        response_double = instance_double(Aws::SSM::Types::GetParametersResult, parameters: [param_double])

        allow(ssm_client).to receive(:get_parameters).with(
          names: ['/plain'],
          with_decryption: true,
        ).and_return(response_double)

        is_expected.to run
          .with_params('plain', options, context)
          .and_return('value_plain')
      end

      it 'finds a secure string' do
        expect(context).to receive(:interpolate)
          .with('/encrypted')
          .and_return('/encrypted')

        param_double = instance_double(Aws::SSM::Types::Parameter, value: 'value_encrypted')
        response_double = instance_double(Aws::SSM::Types::GetParametersResult, parameters: [param_double])

        allow(ssm_client).to receive(:get_parameters).with(
          names: ['/encrypted'],
          with_decryption: true,
        ).and_return(response_double)

        is_expected.to run
          .with_params('encrypted', options, context)
          .and_return('value_encrypted')
      end

      it 'returns not_found when the value does not exist' do
        expect(context).to receive(:interpolate)
          .with('/nonexists')
          .and_return('/nonexists')

        response_double = instance_double(Aws::SSM::Types::GetParametersResult, parameters: [])

        allow(ssm_client).to receive(:get_parameters).with(
          names: ['/nonexists'],
          with_decryption: true,
        ).and_return(response_double)

        expect(context).to receive(:not_found)

        is_expected.to run
          .with_params('nonexists', options, context)
          .and_return(nil)
      end

      it 'finds a string using another region' do
        options['region'] = 'us-east-2'

        expect(Aws::SSM::Client).to receive(:new)
          .with(region: 'us-east-2')
          .and_return(ssm_client)

        expect(context).to receive(:interpolate)
          .with('/region2')
          .and_return('/region2')

        param_double = instance_double(Aws::SSM::Types::Parameter, value: 'ohio')
        response_double = instance_double(Aws::SSM::Types::GetParametersResult, parameters: [param_double])

        allow(ssm_client).to receive(:get_parameters).with(
          names: ['/region2'],
          with_decryption: true,
        ).and_return(response_double)

        is_expected.to run
          .with_params('region2', options, context)
          .and_return('ohio')
      end

      it 'translates :: to /' do
        expect(context).to receive(:interpolate)
          .with('/plain/translate')
          .and_return('/plain/translate')

        param_double = instance_double(Aws::SSM::Types::Parameter, value: 'parameter_value')
        response_double = instance_double(Aws::SSM::Types::GetParametersResult, parameters: [param_double])

        allow(ssm_client).to receive(:get_parameters).with(
          names: ['/plain/translate'],
          with_decryption: true,
        ).and_return(response_double)

        is_expected.to run
          .with_params('plain::translate', options, context)
          .and_return('parameter_value')
      end
    end

    context 'when running without a Hiera context' do
      let(:options) do
        {
          'uri' => '/',
          'region' => 'us-east-1',
          'get_all' => false,
        }
      end

      it 'finds a string' do
        param_double = instance_double(Aws::SSM::Types::Parameter, value: 'value_plain')
        response_double = instance_double(Aws::SSM::Types::GetParametersResult, parameters: [param_double])

        allow(ssm_client).to receive(:get_parameters).with(
          names: ['/plain'],
          with_decryption: true,
        ).and_return(response_double)

        is_expected.to run
          .with_params('plain', options)
          .and_return('value_plain')
      end

      it 'finds a secure string' do
        param_double = instance_double(Aws::SSM::Types::Parameter, value: 'value_encrypted')
        response_double = instance_double(Aws::SSM::Types::GetParametersResult, parameters: [param_double])

        allow(ssm_client).to receive(:get_parameters).with(
          names: ['/encrypted'],
          with_decryption: true,
        ).and_return(response_double)

        is_expected.to run
          .with_params('encrypted', options)
          .and_return('value_encrypted')
      end

      it 'returns nil when the value does not exist' do
        response_double = instance_double(Aws::SSM::Types::GetParametersResult, parameters: [])

        allow(ssm_client).to receive(:get_parameters).with(
          names: ['/nonexists'],
          with_decryption: true,
        ).and_return(response_double)

        is_expected.to run
          .with_params('nonexists', options)
          .and_return(nil)
      end

      it 'finds a string using another region' do
        options['region'] = 'us-east-2'

        expect(Aws::SSM::Client).to receive(:new)
          .with(region: 'us-east-2')
          .and_return(ssm_client)

        param_double = instance_double(Aws::SSM::Types::Parameter, value: 'ohio')
        response_double = instance_double(Aws::SSM::Types::GetParametersResult, parameters: [param_double])

        allow(ssm_client).to receive(:get_parameters).with(
          names: ['/region2'],
          with_decryption: true,
        ).and_return(response_double)

        is_expected.to run
          .with_params('region2', options)
          .and_return('ohio')
      end

      it 'translates :: to /' do
        param_double = instance_double(Aws::SSM::Types::Parameter, value: 'parameter_value')
        response_double = instance_double(Aws::SSM::Types::GetParametersResult, parameters: [param_double])

        allow(ssm_client).to receive(:get_parameters).with(
          names: ['/plain/translate'],
          with_decryption: true,
        ).and_return(response_double)

        is_expected.to run
          .with_params('plain::translate', options)
          .and_return('parameter_value')
      end
    end

    context 'when fetching all keys' do
      let(:options) do
        {
          'uri' => '/',
          'region' => 'us-east-1',
          'get_all' => true,
          'recursive' => true,
        }
      end

      before(:each) do
        allow(context).to receive(:cache_has_key)
          .with('ssm_cached')
          .and_return(false)
      end

      it 'finds a string' do
        expect(context).to receive(:interpolate)
          .with('/plain')
          .and_return('/plain')

        response_double = instance_double(
          Aws::SSM::Types::GetParametersByPathResult,
          next_token: nil,
          parameters: [{ 'name' => 'plain', 'value' => 'value_plain' }],
        )
        allow(response_double).to receive(:[]).with('parameters').and_return([{ 'name' => 'plain', 'value' => 'value_plain' }])

        allow(ssm_client).to receive(:get_parameters_by_path).with(
          path: '/',
          with_decryption: true,
          recursive: true,
          next_token: nil,
        ).and_return(response_double)

        expect(context).to receive(:cache)
          .with('plain', 'value_plain')

        expect(context).to receive(:cache)
          .with('ssm_cached', 'true')

        expect(context).to receive(:cache_has_key)
          .with('plain')
          .and_return(true)

        expect(context).to receive(:cached_value)
          .with('plain')
          .and_return('value_plain')

        is_expected.to run
          .with_params('plain', options, context)
          .and_return('value_plain')
      end

      it 'finds a secure string' do
        expect(context).to receive(:interpolate)
          .with('/encrypted')
          .and_return('/encrypted')

        response_double = instance_double(
          Aws::SSM::Types::GetParametersByPathResult,
          next_token: nil,
          parameters: [{ 'name' => 'encrypted', 'value' => 'value_encrypted' }],
        )
        allow(response_double).to receive(:[]).with('parameters').and_return([{ 'name' => 'encrypted', 'value' => 'value_encrypted' }])

        allow(ssm_client).to receive(:get_parameters_by_path).with(
          path: '/',
          with_decryption: true,
          recursive: true,
          next_token: nil,
        ).and_return(response_double)

        expect(context).to receive(:cache)
          .with('encrypted', 'value_encrypted')

        expect(context).to receive(:cache)
          .with('ssm_cached', 'true')

        expect(context).to receive(:cache_has_key)
          .with('encrypted')
          .and_return(true)

        expect(context).to receive(:cached_value)
          .with('encrypted')
          .and_return('value_encrypted')

        is_expected.to run
          .with_params('encrypted', options, context)
          .and_return('value_encrypted')
      end

      it 'returns not_found when the value does not exist' do
        expect(context).to receive(:interpolate)
          .with('/nonexists')
          .and_return('/nonexists')

        response_double = instance_double(
          Aws::SSM::Types::GetParametersByPathResult,
          next_token: nil,
          parameters: [],
        )
        allow(response_double).to receive(:[]).with('parameters').and_return([])

        allow(ssm_client).to receive(:get_parameters_by_path).with(
          path: '/',
          with_decryption: true,
          recursive: true,
          next_token: nil,
        ).and_return(response_double)

        expect(context).to receive(:cache)
          .with('ssm_cached', 'true')

        expect(context).to receive(:cache_has_key)
          .with('nonexists')
          .and_return(false)

        expect(context).to receive(:cache_has_key)
          .with('/nonexists')
          .and_return(false)

        expect(context).to receive(:not_found)

        is_expected.to run
          .with_params('nonexists', options, context)
          .and_return(nil)
      end

      it 'finds a string using its full path' do
        options['uri'] = '/hiera/'

        expect(context).to receive(:interpolate)
          .with('/hiera/path')
          .and_return('/hiera/path')

        response_double = instance_double(
          Aws::SSM::Types::GetParametersByPathResult,
          next_token: nil,
          parameters: [{ 'name' => '/hiera/path', 'value' => 'fullpath' }],
        )
        allow(response_double).to receive(:[]).with('parameters').and_return([{ 'name' => '/hiera/path', 'value' => 'fullpath' }])

        allow(ssm_client).to receive(:get_parameters_by_path).with(
          path: '/hiera/',
          with_decryption: true,
          recursive: true,
          next_token: nil,
        ).and_return(response_double)

        expect(context).to receive(:cache)
          .with('/hiera/path', 'fullpath')

        expect(context).to receive(:cache)
          .with('ssm_cached', 'true')

        expect(context).to receive(:cache_has_key)
          .with('path')
          .and_return(false)

        expect(context).to receive(:cache_has_key)
          .with('/hiera/path')
          .and_return(true)

        expect(context).to receive(:cached_value)
          .with('/hiera/path')
          .and_return('fullpath')

        is_expected.to run
          .with_params('path', options, context)
          .and_return('fullpath')
      end

      it 'finds a string using another region' do
        options['region'] = 'us-east-2'

        expect(Aws::SSM::Client).to receive(:new)
          .with(region: 'us-east-2')
          .and_return(ssm_client)

        expect(context).to receive(:interpolate)
          .with('/region2')
          .and_return('/region2')

        response_double = instance_double(
          Aws::SSM::Types::GetParametersByPathResult,
          next_token: nil,
          parameters: [{ 'name' => 'region2', 'value' => 'ohio' }],
        )
        allow(response_double).to receive(:[]).with('parameters').and_return([{ 'name' => 'region2', 'value' => 'ohio' }])

        allow(ssm_client).to receive(:get_parameters_by_path).with(
          path: '/',
          with_decryption: true,
          recursive: true,
          next_token: nil,
        ).and_return(response_double)

        expect(context).to receive(:cache)
          .with('region2', 'ohio')

        expect(context).to receive(:cache)
          .with('ssm_cached', 'true')

        expect(context).to receive(:cache_has_key)
          .with('region2')
          .and_return(true)

        expect(context).to receive(:cached_value)
          .with('region2')
          .and_return('ohio')

        is_expected.to run
          .with_params('region2', options, context)
          .and_return('ohio')
      end
    end
  end
end
