class RevisionReportsController < ApplicationController

  def index
    
  end
  
  def by_author
    @report = ActiveWarehouse::Report::TableReport.new(
      :title => "Revisions by Author",
      :cube_name => :revisions_by_author, 
      :column_dimension_name => :date, 
      :row_dimension_name => :author
    )
  end
end
