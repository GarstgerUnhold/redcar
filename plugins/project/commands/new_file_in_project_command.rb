
module Redcar
  class NewFileInProjectCommand < Redcar::Command
    def initialize(path)
      @path = path
    end
    
    def execute
      if pt = ProjectPane.instance
        pt.new_file_at(@path)
      end
    end
  end
end
