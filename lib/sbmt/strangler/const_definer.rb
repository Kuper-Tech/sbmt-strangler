# frozen_string_literal: true

module Sbmt
  module Strangler
    class ConstDefiner
      class << self
        def call!(name, klass)
          const_names = name.split("::")
          class_name = const_names.pop
          module_name = if const_names.any?
            define_modules(const_names)
          else
            Object
          end

          module_name.const_set(class_name, klass)
        end

        private

        def define_modules(module_names)
          module_names.reduce(Object) do |parent_module_name, module_name|
            define_module(module_name, parent_module_name)
            "#{parent_module_name}::#{module_name}".constantize
          end
        end

        def define_module(module_name, parent_module_name)
          return if parent_module_name.const_defined?(module_name)

          parent_module_name.const_set(module_name, Module.new)
        end
      end
    end
  end
end
