module ActiveWarehouse
  module DimensionReflection
    attr_reader :slowly_changing_over
    
    def slowly_changing_over=(reflection)
      @slowly_changing_over = reflection
      add_dependent_dimension_reflection(reflection)
    end
    
    # add a dependent dimension reflection to this dimension reflection.
    # some dimensions require others to operate, e.g. slowly changing dimensions
    def add_dependent_dimension_reflection(dimension_reflection)
      dependent_dimension_reflections << dimension_reflection
    end
    
    # returns array of dependent dimension reflections
    def dependent_dimension_reflections
      @dependent_dimension_reflections ||= []
    end
  end
end