class <%= migration_name %> < ActiveRecord::Migration
  def self.up
    create_table :<%= table_name %> do |t|
      t.column :sql_date_stamp, :date, :null => false                       # SQL Date object
      t.column :calendar_year, :string, :null => false                      # 2005, 2006, 2007, etc.
      t.column :calendar_quarter, :string, :null => false, :limit => 2      # Q1, Q2, Q3 or Q4
      t.column :calendar_quarter_number, :integer, :null => false           # 1, 2, 3 or 4
      t.column :calendar_month_name, :string, :null => false, :limit => 9   # January, February, etc.
      t.column :calendar_month_number, :integer, :null => false             # 1, 2, 3, ... 12
      t.column :calendar_week, :string, :null => false, :limit => 2         # 1, 2, 3, ... 52
      t.column :calendar_week_number, :integer, :null => false              # 1, 2, 3, ... 52
      t.column :day_number_in_calendar_year, :integer, :null => false       # 1, 2, 3, ... 365
      t.column :day_number_in_calendar_month, :integer, :null => false      # 1, 2, 3, ... 31
      t.column :day_in_week, :string, :null => false, :limit => 9           # Monday, Tuesday, etc.
      <%  if include_fiscal_year -%>
      t.column :fiscal_year, :string, :null => false
      t.column :fiscal_quarter, :string, :null => false, :limit => 2
      t.column :fiscal_quarter_number, :integer, :null => false
      t.column :fiscal_month_number, :integer, :null => false
      t.column :fiscal_week, :string, :null => false, :limit => 2
      t.column :fiscal_week_number, :integer, :null => false
      t.column :day_number_in_fiscal_year, :integer, :null => false
      <%  end -%>
    end
    # add indexes as required
  end

  def self.down
    drop_table :<%= table_name %>
  end
end
