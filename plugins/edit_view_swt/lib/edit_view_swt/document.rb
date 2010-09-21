
module Redcar
  class EditViewSWT
    class Document
      include Redcar::Observable
      attr_reader :jface_document

      def initialize(model, swt_mate_document)
        @model          = model
        @swt_mate_document = swt_mate_document
        @jface_document = swt_mate_document.mateText.get_document
      end

      def right_click(edit_view)
        menu = Menu.new
        Redcar.plugin_manager.objects_implementing(:edit_view_context_menus).each do |object|
          case object.method(:edit_view_context_menus).arity
          when 0
            menu.merge(object.edit_view_context_menus)
          when 1
            menu.merge(object.edit_view_context_menus(edit_view))
          else
            puts("Invalid edit_view_context_menus hook detected in "+object.class.name)
          end
        end
        Application::Dialog.popup_menu(menu, :pointer)
      end

      def attach_modification_listeners
        jface_document.add_document_listener(DocumentListener.new(@model))
        styledText.add_selection_listener(SelectionListener.new(@model))
        styledText.add_caret_listener(CaretListener.new(@model))
      end

      def single_line?
        @swt_mate_document.mateText.isSingleLine
      end

      # The entire contents of the document
      #
      # @return [String]
      def to_s
        jface_document.get
      end

      # Length of the document in characters
      #
      # @return [Integer]
      def length
        jface_document.length
      end

      # Number of lines.
      #
      # @return [Integer]
      def line_count
        jface_document.get_number_of_lines
      end

      # Returns the line delimiter for this document. Either
      # \n or \r\n. It will attempt to detect the delimiter from the document
      # or it will default to the platform delimiter.
      #
      # @return [String]
      def line_delimiter
        styledText.get_line_delimiter
      end

      # Get the line index of the given offset
      #
      # @param [Integer] offset zero-based character offset
      # @return [Integer] zero-based index
      def line_at_offset(offset)
        jface_document.get_line_of_offset(offset)
      end

      # Get the character offset at the start of the given line
      #
      # @param [Integer] line   zero-based line index
      # @return [Integer] zero-based character offset
      def offset_at_line(line_ix)
        jface_document.get_line_offset(line_ix)
      end

      def get_line(line_ix)
        line_info = jface_document.get_line_information(line_ix)
        jface_document.get(line_info.offset, line_info.length)
      end

      # Get a range of text from the document.
      #
      # @param [Integer] start  the character offset of the start of the range
      # @param [Integer] length  the length of the string to get
      # @return [String] the text
      def get_range(start, length)
        jface_document.get(start, length)
      end

      # Replace text
      #
      # @param [Integer] offset  character offset from the start of the document
      # @param [Integer] length  length of text to replace
      # @param [String] text  replacement text
      def replace(offset, length, text)
        @model.verify_text(offset, offset+length, text)
        text = text.gsub(line_delimiter, "") if single_line?
        jface_document.replace(offset, length, text)
        #if length > text.length
        #  @swt_mate_document.mateText.redraw
        #end
        @model.modify_text
      end

      # Set the contents of the document
      #
      # @param [String] text  new text
      def text=(text)
        @model.verify_text(0, length, text)
        jface_document.set(text)
        @model.modify_text
        notify_listeners(:set_text)
      end

      # Get the position of the cursor.
      #
      # @return [Integer] zero-based character offset
      def cursor_offset
        styledText.get_caret_offset
      end

      def selection_offset
        range = styledText.get_selection_range
        range.x == cursor_offset ? range.x + range.y : range.x
      end

      # Set the position of the cursor.
      #
      # @param [Integer] offset   zero-based character offset
      def cursor_offset=(offset)
        styledText.set_caret_offset(offset)
      end

      # The range of text selected by the user.
      #
      # @return [Range<Integer>] a range between two character offsets
      def selection_range
        range = styledText.get_selection_range
        range.x...(range.x + range.y)
      end

      # The ranges of text selected by the user.
      #
      # @return [Range<Integer>] a range between two character offsets
      def selection_ranges
        ranges = styledText.get_selection_ranges
        ranges.to_a.each_slice(2).map do |from, length|
          from...(from + length)
        end
      end

      # Set the range of text selected by the user.
      #
      # @param [Integer] cursor_offset
      # @param [Integer] selection_offset
      def set_selection_range(cursor_offset, selection_offset)
        if block_selection_mode?
          start_offset, end_offset = *[cursor_offset, selection_offset].sort
          start_location = styledText.getLocationAtOffset(start_offset)
          end_location   = styledText.getLocationAtOffset(end_offset)
          styledText.set_block_selection_bounds(
            start_location.x,
            start_location.y,
            end_location.x - start_location.x,
            end_location.y - start_location.y + styledText.get_line_height
          )
        else
          styledText.set_selection_range(selection_offset, cursor_offset - selection_offset)
        end
        @model.selection_range_changed(cursor_offset, selection_offset)
      end

      @markStruct ||= Struct.new(:location, :category) # save away the parent class
      class Mark < @markStruct
        def get_offset;      location.get_offset;      end
        def get_line;        location.get_line;        end
        def get_line_offset; location.get_line_offset; end
        def inspect;         "<Mark #{get_line}:#{get_line_offset} (#{get_offset})>"; end
      end

      def create_mark(offset, gravity=:right)
        line = line_at_offset(offset)
        line_offset = offset - offset_at_line(line)
        case gravity
        when :left
          category = "lefts"
        when :right
          category = "rights"
        end
        location = @swt_mate_document.get_text_location(line, line_offset)
        @swt_mate_document.add_text_location(category, location)
        Mark.new(location, category)
      end

      def delete_mark(mark)
        @swt_mate_document.remove_text_location(mark.category, mark.location)
      end

      # Is the document in block selection mode?
      def block_selection_mode?
        styledText.get_block_selection
      end

      # Turn the block selection mode on or off.
      def block_selection_mode=(bool)
        styledText.set_block_selection(!!bool)
      end

      def styledText
        @swt_mate_document.mateText.getControl
      end

      def scope_at(line, line_offset)
        @swt_mate_document.mateText.scope_at(line, line_offset)
      end

      class CaretListener
        def initialize(model)
          @model = model
        end

        def caret_moved(event)
          @model.cursor_moved(event.caretOffset)
        end
      end

      class SelectionListener
        def initialize(model)
          @model = model
        end

        def widget_default_selected(e)
          @model.selection_range_changed(e.x, e.y)
        end

        def widget_selected(e)
          @model.selection_range_changed(e.x, e.y)
        end
      end

      class DocumentListener
        def initialize(model)
          @model = model
        end

        def document_about_to_be_changed(e)
          @model.about_to_be_changed(e.offset, e.length, e.text)
        end

        def document_changed(e)
          @model.changed(e.offset, e.length, e.text)
        end
      end
    end
  end
end
