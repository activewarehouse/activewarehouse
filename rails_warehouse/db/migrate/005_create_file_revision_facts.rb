class CreateFileRevisionFacts < ActiveRecord::Migration
  def self.up
    create_table :file_revision_facts do |t|
      t.column :date_id, :integer, :null => false
      t.column :file_id, :integer, :null => false
      t.column :change_type_id, :integer, :null => false
      t.column :author_id, :integer, :null => false
      t.column :revision, :string, :null => false
      t.column :file_changed, :integer, :default => 1
    end
    add_index :file_revision_facts, :date_id
    add_index :file_revision_facts, :file_id
    add_index :file_revision_facts, :change_type_id
    add_index :file_revision_facts, :author_id
  end

  def self.down
    drop_table :file_revision_facts
  end
end
