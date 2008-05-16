class <%= migration_name %> < ActiveRecord::Migration
  def self.up
    fields = {
      # the following are the required bridge table columns for
      # variable depth hierarchies.  Do not change them unless you know
      # what you are doing.
      :parent_id => :integer,
      :child_id => :integer,
      :num_levels_from_parent => :integer,
      :is_bottom => :boolean,
      :is_top => :boolean
    }
    create_table :<%= table_name %> do |t|
      fields.each do |name,type|
        t.column name, type
      end
    end
    fields.each do |name,type|
      add_index :<%= table_name %>, name unless type == :text      
    end
    add_index :<%= table_name %>, [:parent_id, :child_id, :num_levels_from_parent], :unique => true
  end

  def self.down
    drop_table :<%= table_name %>
  end
end
