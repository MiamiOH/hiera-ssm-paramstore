Puppet::Functions.create_function(:hiera_ssm_paramstore) do
  begin
    require 'aws-sdk-ssm'
  rescue LoadError
    raise Puppet::DataBinding::LookupError, 'Must install gem aws-sdk-ssm to use hiera_ssm_paramstore'
  end

  dispatch :lookup_key do
    param 'Variant[String, Numeric]', :key
    param 'Hash', :options
    optional_param 'Puppet::LookupContext', :context
  end

  def lookup_key(key, options, context = nil)
    key_path = options['uri'] + key.gsub('::', '/')
    key_path = context.interpolate(key_path) if context

    # Searches for key and key path because SSM returns just the key for
    # keys on the root path (/) and the full path for the rest (/path/key).
    if options['get_all'] && context
      if context.cache_has_key('ssm_cached')
        context.explain { 'Cache populated!!!' }
      else
        context.explain { 'No cache, caching...' }
        get_all_parameters(options, context)
      end

      if context.cache_has_key(key)
        context.explain { "Returning value for key #{key}" }
        context.cached_value(key)
      elsif context.cache_has_key(key_path)
        context.explain { "Returning value for #{key}" }
        context.cached_value(key_path)
      else
        context.explain { "Key #{key} not found" }
        context.not_found
      end
    else
      get_parameter(key_path, options, context)
    end
  end

  def ssm_get_connection(options)
    if options['region'].nil?
      Aws::SSM::Client.new
    else
      Aws::SSM::Client.new(region: options['region'])
    end
  rescue Aws::SSM::Errors::ServiceError => e
    raise Puppet::DataBinding::LookupError, "Fail to connect to aws ssm #{e.message}"
  end

  def get_all_parameters(options, context)
    token = nil
    options['recursive'] ||= false
    ssmclient = ssm_get_connection(options)

    loop do
      context.explain { "Getting keys on #{options['uri']} ..." }

      data = ssmclient.get_parameters_by_path(
        path: options['uri'],
        with_decryption: true,
        recursive: options['recursive'],
        next_token: token,
      )

      context.explain { 'Adding keys on cache ...' }

      data['parameters'].each do |parameter|
        context.cache(parameter['name'], parameter['value'])
      end

      context.explain { 'Marking cache as populated' }
      context.cache('ssm_cached', 'true')

      break if data.next_token.nil?

      token = data.next_token
    rescue Aws::SSM::Errors::ServiceError => e
      raise Puppet::DataBinding::LookupError,
            "AWS SSM Service error #{e.message} with path: #{options['uri']}"
    end
  end

  def get_parameter(key_path, options, context)
    ssmclient = ssm_get_connection(options)

    if context&.cache_has_key(key_path)
      context.explain { "Returning cached value for #{key_path}" }
      context.cached_value(key_path)
    else
      context&.explain { "Looking for #{key_path}" }

      begin
        resp = ssmclient.get_parameters(
          names: [key_path],
          with_decryption: true,
        )

        if !resp.parameters.empty?
          value = resp.parameters[0].value
          context&.cache(key_path, value)
          value
        elsif context
          context.explain { "Key #{key_path} not found" }
          context.not_found
        else
          nil
        end
      rescue Aws::SSM::Errors::ServiceError => e
        raise Puppet::DataBinding::LookupError,
              "AWS SSM Service error #{e.message} with names: [#{key_path}]"
      end
    end
  end
end
