class	Crumb
	def initialize(stage, dimension, params)
		@params = params.dup
		@stage = stage
		@hierarchy = dimension.hierarchy
		@name = dimension.ancestors[@stage-1] if @stage > 0
	end
	
	def link_to_params
		invalid_params = @hierarchy[@stage..-1].map {|h| hierarchy_param(h) }.flatten
		@params.delete_if { |k, v| invalid_params.include?(k) }
	end
	
	def link_to_name
		@name || 'Top'
	end
end

class RowCrumb < Crumb
	def initialize(stage, dimension, params)
		super
		@params[:rstage] = @stage.to_s
	end
	
	#TODO - brittle, drive off of report's prefix param
	def hierarchy_param(name)
		"r_#{name}"
	end
	
	def crumb_type
		"Row"
	end

	def self.gather(dimension, params)
		crumbs = []
		(0..dimension.stage).each do |stage|
			crumbs << RowCrumb.new(stage, dimension, params)
		end
		crumbs
	end
end

class ColumnCrumb < Crumb
	def initialize(stage, dimension, params)
		super
		@params[:cstage] = @stage.to_s
	end

	def hierarchy_param(name)
		"c_#{name}"
	end

	def crumb_type
		"Column"
	end

	def self.gather(dimension, params)
		crumbs = []
		(0..dimension.stage).each do |stage|
			crumbs << ColumnCrumb.new(stage, dimension, params)
		end
		crumbs
	end
end
