class CreateFileDimension < ActiveRecord::Migration
  def self.up
    fields = {
      :path => :string,
      :directory => :string,
      :file_name => :string,
      :file_base => :string,
      :file_type => :string,
      :extension => :string,
      :framework => :string
    }
    create_table :file_dimension do |t|
      fields.each do |name,type|
        t.column name, type
      end
    end
    fields.each do |name,type|
      add_index :file_dimension, name unless type == :text      
    end
  end

  def self.down
    drop_table :file_dimension
  end
end
