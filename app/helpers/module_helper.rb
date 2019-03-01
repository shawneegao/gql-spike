module ModuleHelper
    # Defines constants on the current module, freezes values
    def def_constants(constant_values)
      all_values = if constant_values.is_a?(Hash)
        constant_values.each do |name, value|
          const_set(name, value.freeze)
        end

        if constant_values.values.all? { |value| value.is_a?(Array) }
          constant_values.values.reduce(:+)
        else
          constant_values.values
        end
      else
        constant_values.each do |value|
          const_set(value, value.freeze)
        end

        constant_values
      end

      const_set(:ALL, all_values.freeze)
    end

    # This hearty dose of metaprogramming might be overkill,
    # but in the spirit of DRY, it's a lot cleaner than this:
    #
    #   module ModuleName
    #     SOME_VALUE  = 'some_value'.freeze
    #     OTHER_VALUE = 'other_value'.freeze
    #
    #     ALL = [SOME_VALUE, OTHER_VALUE].freeze
    #   end
    #
    # Notes:
    #  - When the values in constant_values are arrays, the ALL
    #    is a concatenation of those arrays
    def def_module(module_name, constant_values)
      mod = Module.new do
        extend ModuleHelper

        def_constants(constant_values)
      end

      const_set(module_name, mod)
    end
  end

