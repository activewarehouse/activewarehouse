module ActiveWarehouse
	module Report

		class DataCell
			
			attr_accessor :column_dimension_value, :row_dimension_value, :fact_attribute, :raw_value, :value
			
			def initialize(column_dimension_value, row_dimension_value, fact_attribute, raw_value, value)
				@column_dimension_value = column_dimension_value 
				@row_dimension_value = row_dimension_value
				@fact_attribute = fact_attribute 
				@raw_value = raw_value
				@value = value
			end
			
			def key
				"#{column_dimension_value}_#{fact_attribute.label}".gsub(' ', '_').downcase
			end			
		end
	end
end