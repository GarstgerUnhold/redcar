
module Redcar
  class DeletePathInProjectCommand < Redcar::Command
    key "Delete"
    range Redcar::ProjectPane
    
    def initialize(path=nil)
      # If no path is given, fetch the path for the currently selected node
      @path = path || ProjectPane.instance.view.selection.selected[2]
    end
    
    def execute
      if pt = ProjectPane.instance
        pt.delete_path(@path)
      end
    end
  end
end
