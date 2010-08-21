module Redcar #TODO: Fix this!!!
  # This class implements the search-and-replace command
  class TextUtils
    # Create the search and replace menu item
    def self.menus
      # Here's how the plugin menus are drawn. Try adding more
      # items or sub_menus.
      Menu::Builder.build do
        sub_menu "Edit" do
          item "Toggle Block Comment", ToggleBlockCommentCommand
        end
      end
    end
    
    def self.keymaps
      osx = Redcar::Keymap.build("main", :osx) do
        link "Cmd+/", ToggleBlockCommentCommand
      end
      linwin = Redcar::Keymap.build("main", [:linux, :windows]) do
        link "Ctrl+/", ToggleBlockCommentCommand
      end
      [osx, linwin]
    end
    
    
    # Toggle block command.
    class ToggleBlockCommentCommand < Redcar::EditTabCommand
      # The execution reuses the same dialog.
      def execute
        adoc = Redcar::app.focussed_notebook_tab.document
        comment = adoc.comment        
        range = doc.selection? ? adoc.selection_range : (adoc.cursor_offset..adoc.cursor_offset)
        start_line = adoc.line_at_offset(range.first)
        end_line = adoc.line_at_offset(range.last)
        (start_line..end_line).each do |line|
          text = adoc.get_line(line).chomp
          ws_ix = text.index(text.lstrip)
          text = if text[ws_ix..ws_ix + comment.length - 1].include? comment
            text[0..ws_ix - 1].concat(text.sub(comment, "").lstrip)
          else 
            text.insert(ws_ix, comment + " ")
          end
          adoc.replace_line(line, text) #TODO: and fix this too!
        end
      end
    end
  end
end