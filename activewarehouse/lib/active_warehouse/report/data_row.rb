module ActiveWarehouse
	module Report

		class DataRow
			
			attr_accessor :cells, :dimension_value
			
			def initialize(dimension_value, cells)
				@dimension_value = dimension_value
				@cells = cells
			end
			
		end
	end
end
