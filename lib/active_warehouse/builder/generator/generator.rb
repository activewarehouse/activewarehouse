module ActiveWarehouse
  module Builder
    module Generator
      # Base class for generators
      class Generator
        # Get the next value from the generator.
        def next(options={})
          raise "Abstract method"
        end
      end
    end
  end
end