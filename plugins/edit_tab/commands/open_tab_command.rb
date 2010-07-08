module Redcar
  class OpenTabCommand < Redcar::Command
    key "Ctrl+O"
    icon :NEW

    def initialize(filename=nil, pane=nil)
      @filename = filename
      @pane = pane
    end

    def open
      if tab = EditTab.find_tab_for_file(@filename)
        tab.focus
        tab
      elsif @filename and File.file?(@filename)
        p win
        new_tab = (@pane||win).new_tab(Redcar::EditTab)
        new_tab.load(@filename)
        new_tab.focus
        new_tab
      else
        puts "no file: #{@filename}"
      end
    end

    def execute
      if !@filename
        Redcar::Dialog.open(win) do |filename|
          if filename 
            @filename = filename
            open
          end
        end
      else
        open
      end
    end
  end
end
