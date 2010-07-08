
module Redcar
  class RemoveDirectoryFromProjectCommand < Command
    def initialize(path)
      @path = path
    end
  
    def execute
      if project_pane = ProjectPane.instance
        project_pane.remove_project(@path)
     end
    end
  end
end
