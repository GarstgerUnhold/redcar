
module Redcar
  class AddDirectoryToProjectCommand < Command
    menu "Project/Add Directory"
    
    def initialize(dir=nil)
      @dirname = dir
    end
    
    def execute
      unless project_pane = ProjectPane.instance
	      project_pane = win.new_tab(ProjectPane)
	      project_pane.focus
			end
      @dirname ||= Redcar::Dialog.open_folder
      if @dirname
        project_pane.add_directory(@dirname.split("/").last, @dirname)
      end
    end
  end
end
