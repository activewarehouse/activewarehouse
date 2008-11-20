fields = {
  :date => :string,
  :full_date_description => :text,
  :day_of_week => :string,
  :day_number_in_epoch => :integer,
  :week_number_in_epoch => :integer,
  :month_number_in_epoch => :integer,
  :day_number_in_calendar_month => :integer,
  :day_number_in_calendar_year => :integer,
  :day_number_in_fiscal_month => :integer,
  :day_number_in_fiscal_year => :integer,
  :last_day_in_week_indicator => :string,
  :last_day_in_month_indicator => :string,
  :calendar_week => :string,
  :calendar_week_ending_date => :string,
  :calendar_week_number_in_year => :integer,
  :calendar_month_name => :string,
  :calendar_month_number_in_year => :integer,
  :calendar_year_month => :string,
  :calendar_quarter => :string,
  :calendar_year_quarter => :string,
  :calendar_half_year => :string,
  :calendar_year => :string,
  :fiscal_week => :string,
  :fiscal_week_number_in_year => :integer,
  :fiscal_year_month => :string,
  :fiscal_quarter => :string,
  :fiscal_year_quarter => :string,
  :fiscal_half_year => :string,
  :fiscal_year => :string,
  :holiday_indicator => :string,
  :weekday_indicator => :string,
  :selling_season => :string,
  :major_event => :string,
  :sql_date_stamp => :date
}
connection = ActiveRecord::Base.connection

begin
  connection.create_table :date_dimension, :force=>true do |t|
    fields.each do |name,type|
      t.column name, type
    end
  end
rescue
  
end

