
module Redcar
  class PreviousTab < Redcar::TabCommand
    key "Ctrl+Page_Up"
    
    def execute
      tab.pane.notebook.prev_page
    end
  end
end
