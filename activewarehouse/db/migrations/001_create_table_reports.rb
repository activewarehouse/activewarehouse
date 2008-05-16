class CreateTableReports < ActiveRecord::Migration
  def self.up
    create_table :table_reports do |t|
      t.column :title, :string
      t.column :cube_name, :string, :null => false
      
      t.column :column_dimension_name, :string
      t.column :column_hierarchy, :string
      t.column :column_constraints, :text
      t.column :column_stage, :integer
      t.column :column_param_prefix, :string
      
      t.column :row_dimension_name, :string
      t.column :row_hierarchy, :string
      t.column :row_constraints, :text
      t.column :row_stage, :integer
      t.column :row_param_prefix, :string
      
      t.column :fact_attributes, :text
      
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end
  def self.down
    drop_table :table_reports
  end
end