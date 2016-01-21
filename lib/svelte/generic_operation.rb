module Svelte
  # Class that handles the actual execution of dynamically generated operations
  # Each created operation will eventually call this class in order to make the
  # final HTTP request to the REST endpoint
  class GenericOperation
    class << self
      # Make an HTTP request to a REST resource
      # @param verb [String] http verb to use, i.e. `'get'`
      # @param path [Path] Path object containing information about the
      #   operation to be called
      # @param configuration [Configuration] Swagger API configuration
      # @param parameters [Hash] payload of the request, i.e. `{ petId: 1}`
      # @param options [Hash] request options, i.e. `{ timeout: 10 }`
      def call(verb:, path:, configuration:, parameters:, options:)
        url = url_for(configuration: configuration,
                      path: path,
                      parameters: parameters)
        request_parameters = clean_parameters(path: path,
                                              parameters: parameters)
        RestClient.call(verb: verb,
                        url: url,
                        params: request_parameters,
                        options: options)
      end

      private

      def url_for(configuration:, path:, parameters:)
        url_path =
          [
            path.non_parameter_elements,
            named_parameters(path: path, parameters: parameters)
          ].flatten.join('/')

        protocol = configuration.protocol
        host = configuration.host
        base_path = configuration.base_path
        "#{protocol}://#{host}#{base_path}#{url_path}"
      end

      def named_parameters(path:, parameters:)
        path.parameter_elements.map do |parameter_element|
          unless parameters.key?(parameter_element)
            raise ParameterError,
                 "Required parameter `#{parameter_element}` missing"
          end
          parameters[parameter_element]
        end
      end

      def clean_parameters(path:, parameters:)
        clean_parameters = parameters.dup
        path.parameter_elements.each do |parameter_element|
          clean_parameters.delete(parameter_element)
        end
        clean_parameters
      end
    end
  end
end
