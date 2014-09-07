require 'spec_helper'

describe ActiveWarehouse::Bridge do

  describe ".table_name" do
    it "returns the table version of the class name" do
      expect(CustomerHierarchyBridge.table_name).to eq('customer_hierarchy_bridge')
    end
  end

end
