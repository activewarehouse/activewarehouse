class Create<%= class_name.pluralize.delete('::') %> < ActiveRecord::Migration
  def self.up
    create_table :<%= table_name %> do |t|
    <%- for attribute in model_attributes -%>
      t.<%= attribute.type %> :<%= attribute.name %>
    <%- end -%>
    end
  end

  def self.down
    drop_table :<%= table_name %>
  end
end
