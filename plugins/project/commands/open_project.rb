
module Redcar
  class OpenProject < Command
    menu "Project/Open"
    key  "Ctrl+Shift+P"
    
    def execute
      unless ProjectPane.instance
        win.panes.first.split_vertical(:left => ProjectPane)
      end
    end
  end
end
