
module Redcar
  # A Pane is a fixed viewport. A Redcar window may have multiple
  # Panes. Panes can be split horizontally and vertically to allow
  # the user to lay out their workspace as they see fit.
  #
  # Plugin authors should not create Panes by hand, rather they should
  # use Pane#split_horizontal and Window#panes to create and locate
  # panes.
  class Pane
    extend FreeBASE::StandardPlugin
    include FreeBASE::DataBusHelper

    # The Window the Pane is in.
    attr_accessor :window

    # Do not call this directly. Creates a new pane
    # attached to the given window. Redcar::Window manages
    # the creation of panes.
    def initialize(window, options={})
      @window, @options = window, (options||{})
    end

    # Replace this Pane in the Window with two new Panes, on
    # the left and right.
    #
    # opts :left => NotebookPane, :right => ProjectPane
    def split_vertical(opts={})
      @window.split_vertical(self, opts)
    end

    # Replace this Pane in the Window with two new Panes, on
    # the top and bottom.
    #
    # opts :top => NotebookPane, :bottom => ProjectPane
    def split_horizontal(opts={})
      @window.split_horizontal(self, opts)
    end

    # Undo the split_horizontal or split_vertical that created
    # this tab.
    def unify
      @window.unify(self)
    end
    
    # Calls gtk_widget, which subclasses should implement to
    # return the gtk_widget that is displayed as the pane.
    def widget
      return @_widget if @_widget
      if @options.include?(:chrome) and !@options[:chrome]
        @_widget = gtk_widget
      else
        @_widget = Gtk::Frame.new(self.class.name)
        @_widget.add(gtk_widget)
        @_widget
      end
      @_widget.show_all
      @_widget
    end
    
    # Useful in testing. Subclasses should override with something 
    # more meaningful.
    def visible_contents_as_string
      gtk_widget.inspect
    end
  end
end
