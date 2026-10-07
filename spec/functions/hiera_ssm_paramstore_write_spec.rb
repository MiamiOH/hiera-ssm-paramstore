# frozen_string_literal: true

require 'aws-sdk-ssm'

Puppet::Functions.create_function(:hiera_ssm_paramstore_write) do
  dispatch :write_key do
    param 'String', :key
    param 'String', :value
    optional_param 'Hash', :options
  end

  def write_key(key, value, options = {})
    options = {
      'uri' => '/',
      'region' => 'us-east-1',
      'get_all' => false,
      'put' => {
        'overwrite' => true,
      },
    }.merge(options)

    parameter_name = "#{options['uri']}#{key.gsub('::', '/')}"

    put_options = options['put'] || {}

    type = put_options['type'] || 'String'
    overwrite = put_options.key?('overwrite') ? put_options['overwrite'] : true

    tags = put_options['tags'] || [
      {
        key: 'CreatedBy',
        value: 'puppet',
      },
    ]

    ssm_client = Aws::SSM::Client.new(
      region: options['region'],
    )

    ssm_client.put_parameter(
      **{
        description: 'Added by hiera_ssm_paramstore_write',
        name: parameter_name,
        overwrite:,
        tags:,
        type:,
        value:,
      },
    )

    value
  end
end
