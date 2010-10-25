class <%= migration_name %> < ActiveRecord::Migration
  def self.up
    create_view "<%= view_name %>", "<%= view_query %>" do |t|
      <%- view_attributes.each do |view_attribute| -%>
      <%-  if view_attribute == 'id' -%>
      t.column :id
      <%-  else -%>
      t.column :<%= name %>_<%= view_attribute %>
      <%-  end -%>
      <%-  end -%>
    end
  end

  def self.down
    drop_view "<%= view_name %>"
  end
end
