require 'active_warehouse/view/report_helper'
require 'active_warehouse/view/table_view'
require 'active_warehouse/view/crumb'
require 'active_warehouse/view/yui_adapter'
ActionView::Base.send :include, ReportHelper # TODO scope by ActiveWarehouse
ActionView::Base.send :include, ActiveWarehouse::View::YuiAdapter

