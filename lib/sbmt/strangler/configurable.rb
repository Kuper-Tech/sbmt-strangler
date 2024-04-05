# frozen_string_literal: true

module Sbmt
  module Strangler
    module Configurable
      def option(*hash)
        hash in [*attributes, Hash => options]

        attributes.each do |attribute|
          define_method :"#{attribute}=" do |value|
            instance_variable_set(:"@#{attribute}", value)
          end

          define_method attribute.to_s do
            value = instance_variable_get(:"@#{attribute}")
            return value if value

            if options[:default_from]
              value = instance_variable_get(options[:default_from])&.public_send(attribute)
            end

            value || options[:default]
          end
        end
      end
    end
  end
end
