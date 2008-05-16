class CreateDateDimension < ActiveRecord::Migration
  def self.up
    fields = {
      :date => :string,
      :day_of_week => :string,
      :day_number_in_calendar_month => :integer,
      :day_number_in_calendar_year => :integer,
      :calendar_week => :string,
      :calendar_week_ending_date => :string,
      :calendar_week_number_in_year => :integer,
      :calendar_month_name => :string,
      :calendar_month_number_in_year => :integer,
      :calendar_year_month => :string,
      :calendar_quarter => :string,
      :calendar_year_quarter => :string,
      :calendar_year => :string,
      :major_event => :string,
      :sql_date_stamp => :date
    }
    create_table :date_dimension do |t|
      fields.each do |name,type|
        t.column name, type
      end
    end
    fields.each do |name,type|
      add_index :date_dimension, name unless type == :text      
    end
  end

  def self.down
    drop_table :date_dimension
  end
end
