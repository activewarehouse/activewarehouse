# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 1) do

  create_table "table_reports", :force => true do |t|
    t.string   "title"
    t.string   "cube_name",             :null => false
    t.string   "column_dimension_name"
    t.string   "column_hierarchy"
    t.text     "column_constraints"
    t.integer  "column_stage"
    t.string   "column_param_prefix"
    t.string   "row_dimension_name"
    t.string   "row_hierarchy"
    t.text     "row_constraints"
    t.integer  "row_stage"
    t.string   "row_param_prefix"
    t.text     "fact_attributes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
