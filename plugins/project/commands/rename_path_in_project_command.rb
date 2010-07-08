
module Redcar
  class RenamePathInProjectCommand < Redcar::Command
    def initialize(path)
      @path = path
    end
    
    def execute
      if project_pane = ProjectPane.instance
        project_pane.rename_path(@path)
      end
    end
  end
end
