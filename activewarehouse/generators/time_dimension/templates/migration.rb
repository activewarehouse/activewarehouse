class <%= migration_name %> < ActiveRecord::Migration
  def self.up
    create_table :<%= table_name %> do |t|
      t.column :hour_of_day, :integer, :null => false
      t.column :minute_of_hour, :integer, :null => false
    end
  end

  def self.down
    drop_table :<%= table_name %>
  end
end
