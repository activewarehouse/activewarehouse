# ActiveWarehouse

The ActiveWarehouse library provides classes and functions which help with
building Data Warehouses using Rails.

## Installation

To install ActiveWarehouse, add the gem to your Gemfile:

  gem 'activewarehouse'

## Generators

ActiveWarehouse comes with several generators

  script/generate fact Sales
  script/generate fact sales
 
    Creates a SalesFact class and a sales_facts table.
 
  script/generate dimension Region
  script/generate dimension region
   
    Creates a RegionDimension class and a region_dimension table.
 
  script/generate cube RegionalSales
  script/generate cube regional_sales
 
    Creates a RegionalSalesCube class.
   
  script/generate bridge CustomerHierarchy
  script/generate bridge customer_hierarchy
   
    Creates a CustomerHierarchyBridge class.
   
  script/generate dimension_view OrderDate Date
  script/generate dimension_view order_date date
  
    Creates an OrderDateDimension class which is represented by a view on top
    of the DateDimension.
   
The rules for naming are as follows:

Facts:
  Fact classes and tables follow the typical Rails rules: classes are singular
  and tables are pluralized. 
  Both the class and table name are suffixed by "_fact".
Dimensions:
  Dimension classes and tables are both singular. 
  Both the class name and the table name are suffixed by "_dimension".
Cube:
  Cube class is singular. If a cube table is created it will also be singular.
Bridge:
  Bridge classes and tables are both singular.
  Both the class name and the table name are suffixed by "_bridge".
Dimension View:
  Dimension View classes are singular. The underlying data structure is a view
  on top of an existing dimension.
  Both the class name and the view name are suffixed by "_dimension"
  
## ETL

The ActiveWarehouse plugin does not directly handle Extract-Transform-Load
processes, however the ActiveWarehouse ETL gem (installed separately) can help.
To install it use:

  gem install activewarehouse-etl
  
More information on the ETL process can be found at
http://activewarehouse.rubyforge.org/etl
