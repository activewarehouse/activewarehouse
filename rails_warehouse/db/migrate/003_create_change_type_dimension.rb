class CreateChangeTypeDimension < ActiveRecord::Migration
  def self.up
    fields = {
      :change_type_code => :string,
      :change_type_description => :string
    }
    create_table :change_type_dimension do |t|
      fields.each do |name,type|
        t.column name, type
      end
    end
    fields.each do |name,type|
      add_index :change_type_dimension, name unless type == :text      
    end
  end

  def self.down
    drop_table :change_type_dimension
  end
end
