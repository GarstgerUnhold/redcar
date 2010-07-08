
module Redcar
  class NextTab < Redcar::TabCommand
    key "Ctrl+Page_Down"
    
    def execute
      tab.pane.notebook.next_page
    end
  end
end

