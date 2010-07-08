
module Redcar
  # A Redcar Window contains a menu bar, a collection of Panes and a status bar.
  # At the moment, there may only be one Window open in an instance of the Redcar
  # application. This should change, hopefully soon.
  class Window < Gtk::Window
    include FreeBASE::DataBusHelper

    attr_reader :widgets_panes, :previous_tab, :gtk_menubar,
                :focussed_gtk_widget

    # Do not call this directly, use App#new_window instead.
    # Creates a new Redcar window.
    def initialize
      title = "Redcar"
      super(title)
      @widgets_panes = {}
      @focussed_tab = nil
      @focussed_gtk_widget = nil
      build_widgets
      MenuDrawer.draw_menus(self)
      Range.activate(Redcar::Window)
      connect_signals
      show_initial_widgets
    end

    # Close this Redcar window.
    def close
      App.close_window(self, true)
    end

    # Returns an array of all the Panes in the Window in a well-defined
    # order. Panes may be filtered to only include instances of subclasses
    # of klass. e.g.
    #
    #    win.panes(NotebookPane)
    def panes(klass=nil)
      result = []
      traverse_panes {|pane| result << pane if !klass or pane.class <= klass}
      result
    end

    # Unifies all the Panes into one.
    def unify_all
      while panes.length > 1
        panes.first.unify
      end
    end

    # Equivalent to calling Pane#new_tab on the currently
    # focussed Pane.
    def new_tab(tab_class, *args)
      pane_for_tab_class(tab_class).new_tab(tab_class, *args)
    end

    # Returns an array of all tabs in the Window.
    def tabs
      panes(NotebookPane).map {|pane| pane.tabs }.flatten
    end

    # Returns an array of all open tabs that are instances of klass.
    def collect_tabs(klass)
      tabs.select {|t| t.is_a? klass}
    end

    define_method_bracket :tab do |id|
      if id.is_a? String
        tabs.find{|t| t.label.text == id}
      end
    end

    # Returns an array of all active tabs (all tabs at the
    # forefront of their Panes).
    def active_tabs
      panes(NotebookPane).map {|p| p.active_tab}.compact
    end

    # Returns the currently focussed Tab in the Window.
    def focussed_tab
      if @focussed_tab
        @focussed_tab
      else
        active_tabs.first
      end
    end

    def split_horizontal(pane, opts={}) #:nodoc:
      split_pane(:horizontal, pane, opts)
    end

    def split_vertical(pane, opts={}) #:nodoc:
      split_pane(:vertical, pane, opts)
    end

    def close_tab(tab) #:nodoc:
      if tab.pane
        nb = tab.pane.notebook
        unless nb.destroyed?
          nb.remove_page(nb.page_num(tab.gtk_nb_widget))
          Tab.widget_to_tab.delete tab.gtk_nb_widget
          if nb.n_pages > 0
            update_focussed_tab(Tab.widget_to_tab[nb.page_child])
          else
            if nexttab = active_tabs.first
              nexttab.gtk_tab_widget.grab_focus
              update_focussed_tab(nexttab)
            else
              update_focussed_tab(nil)
            end
          end
        end
        Hook.trigger :close_tab, tab
        update_tab_range(focussed_tab)
      else
        raise "trying to close tab with no pane: #{tab.label.text}"
      end
    end

    def unify(pane) #:nodoc:
      panes_container = pane.widget.parent
      unless panes_container.class == Gtk::HBox
        other_side = panes_container.children.find {|c| c != pane.widget }
        panes_container.remove(pane.widget)
        panes_container.remove(other_side)
        if [Gtk::HPaned, Gtk::VPaned].include? other_side.class
          other_tabs = collect_tabs_from_dual(other_side)
        else
          p other_side
          if (pane = @widgets_panes[other_side]).is_a?(Redcar::NotebookPane)
            p pane
            other_tabs = pane.tabs
            p other_tabs
          else
            other_tabs = []
          end
          @widgets_panes.delete other_side
        end
        container_of_container = panes_container.parent
        other_panes = other_tabs.map {|t| t.pane }.uniq
        other_tabs.each do |tab|
          tab.pane.move_tab(tab, pane)
        end
        if container_of_container.class == Gtk::HBox
          container_of_container.remove panes_container
          container_of_container.pack_start pane.widget
        else
          if container_of_container.child1 == panes_container
            container_of_container.remove panes_container
            container_of_container.add1 pane.widget
          else
            container_of_container.remove panes_container
            container_of_container.add2 pane.widget
          end
        end
      end
    end

    def update_focussed_tab(tab) #:nodoc:
      Hook.trigger :focus_tab, tab do
        @previously_focussed_tab = @focussed_tab
        @focussed_tab = tab
      end
      update_tab_range(tab)
    end

    def open_modal_dialogs
      @open_modal_dialogs ||= []
    end

    class ModalDialogRunner
      def initialize(window, dialog)
        @window, @dialog = window, dialog
      end

      # Run the dialog in modal mode. Note that this method
      # will immediately return, so operations that depend on
      # the dialog being closed must hook onto dialog response
      # signals.
      def run
        # Ignore all input to the window while the dialog is open
        @modal_key_handler = @window.signal_connect("key-press-event") { true }
        @modal_click_handler = @window.signal_connect("button-press-event") { true }
        @dialog.show_all
        @window.open_modal_dialogs << self
      end
      
      def close
        @dialog.destroy
        @window.signal_handler_disconnect(@modal_key_handler)
        @window.signal_handler_disconnect(@modal_click_handler)
        @window.open_modal_dialogs.delete(self)
      end
    end
    
    # We can't use the standard Gtk modal dialog option
    # because it hangs the main event loop waiting for input
    # which means we can't test it.
    def modal_dialog_runner(dialog)
      ModalDialogRunner.new(self, dialog)
    end
   
    private
    
    # Iterates over the panes in the window in a well-defined order.
    def traverse_panes(&block)
      traverse_panes_inner(bus["/gtk/window/panes_container"].data, &block)
    end
    
    def traverse_panes_inner(gtk_widget, &block)
      if pane = @widgets_panes[gtk_widget]
        yield pane
      else
        if gtk_widget.respond_to?(:children)
          gtk_widget.children.each do |child|
            traverse_panes_inner(child, &block)
          end
        end
      end
    end
    
    def pane_for_tab_class(tab_class)
      panes(NotebookPane).reverse.sort_by do |pane|
        num_same_class = pane.tabs.select {|t| t.is_a? tab_class}.length
        num = pane.tabs.length
        num_same_class*100 - (num - num_same_class)
      end.last
    end
    
    def collect_tabs_from_dual(dual)
      [dual.child1, dual.child2].map do |child|
        if child.class == Gtk::Notebook or
            child.child.class == Gtk::Notebook
          @widgets_panes[child].tabs
        else
          collect_tabs_from_dual(child)
        end
      end.flatten
    end

    def split_pane(whichway, pane, opts)
      case whichway
      when :horizontal
        dual = Gtk::VPaned.new
        klass = opts[:top] || opts[:bottom] || NotebookPane
      when :vertical
        dual = Gtk::HPaned.new
        klass = opts[:left] || opts[:right] || NotebookPane
      end
      new_pane = klass.new(self)
      @widgets_panes[new_pane.widget] = new_pane
      panes_container = pane.widget.parent
      if panes_container.class == Gtk::HBox
        panes_container.remove(pane.widget)
        dual.add(new_pane.widget)
        dual.add(pane.widget)
        panes_container.pack_start(dual)
      else
        if panes_container.child1 == pane.widget # (on the left or top)
          panes_container.remove(pane.widget)
          dual.add(new_pane.widget)
          dual.add(pane.widget)
          panes_container.add1(dual)
        else
          panes_container.remove(pane.widget)
          dual.add(new_pane.widget)
          dual.add(pane.widget)
          panes_container.add2(dual)
        end
      end
      dual.show
      dual.position = 250
      Hook.trigger(:new_pane, new_pane)
      new_pane
    end

    def notebook_to_pane(nb)
      @notebooks_panes[nb]
    end

    def connect_signals
      signal_connect("destroy") do
        self.close
      end

      signal_connect("size-request") do 
        Redcar::App[:window_size] = self.size
      end

      signal_connect('key-press-event') do |gtk_widget, gdk_eventkey|
        done = false
        if speedbar_display = speedbar_focussed?
          done = speedbar_display.process_keypress(gdk_eventkey)
        end
        if done
          false
        else
          stop_propogating = nil
          begin
            stop_propogating = Keymap.process(gdk_eventkey)
          rescue Object => e
            App.log.error e
            App.log.error e.backtrace
          end
          
          # falls through to Gtk widgets if nothing handles it
          stop_propogating
        end
      end

      # Everytime the focus changes, check to see if we have changed tabs.
      signal_connect('set-focus') do |_, gtk_widget, _|
        @focussed_gtk_widget = gtk_widget
        until gtk_widget == nil or
            Tab.widget_to_tab.keys.include? gtk_widget or
            @widgets_panes.keys.include? gtk_widget
          gtk_widget = gtk_widget.parent
        end
        if gtk_widget
          if tab = Tab.widget_to_tab[gtk_widget]
            update_focussed_tab(tab)
          elsif pane = @widgets_panes[gtk_widget] and pane.is_a?(NotebookPane) # TODO: fix hardcoded ref
            notebook = pane.notebook
            pageid = notebook.page
            gtk_nb_widget = notebook.get_nth_page(pageid)
            update_focussed_tab(Tab.widget_to_tab[gtk_nb_widget])
          end
        end
      end
    end

    def focussed_speedbar
      w = @focussed_gtk_widget
      while w and !w.is_a? Redcar::SpeedbarDisplay
        w = w.parent
      end
      w
    end

    def speedbar_focussed?
      focussed_speedbar
    end

    def build_widgets
      window_size = Redcar::App[:window_size] || [800, 600]
      set_default_size(*window_size)
      @gtk_menubar = Gtk::MenuBar.new
      gtk_table = Gtk::Table.new(1, 3, false)
      bus["/gtk/window/table"].data = gtk_table
      bus["/gtk/window/menubar"].data = @gtk_menubar
      gtk_table.attach(@gtk_menubar,
                       # X direction            # Y direction
                       0, 1,                    0, 1,
                       Gtk::EXPAND | Gtk::FILL, 0,
                       0,                       0)
      gtk_toolbar = Gtk::Toolbar.new
      bus["/gtk/window/toolbar"].data = gtk_toolbar
      gtk_table.attach(gtk_toolbar,
                       # X direction            # Y direction
                       0, 1,                    1, 2,
                       Gtk::EXPAND | Gtk::FILL, 0,
                       0,                       0)
      gtk_project = Gtk::Button.new("PROJECT")
      gtk_panes_box = Gtk::HBox.new
      gtk_edit_view = Gtk::HBox.new
      bus["/gtk/window/editview"].data = gtk_edit_view
      bus["/gtk/window/panes_container"].data = gtk_panes_box
      gtk_edit_view.pack_start(gtk_project)
      gtk_edit_view.pack_start(gtk_panes_box)
      gtk_table.attach(gtk_edit_view,
                   # X direction            # Y direction
                   0, 1,                    2, 3,
                   Gtk::EXPAND | Gtk::FILL, Gtk::EXPAND | Gtk::FILL,
                   0,      0)
      gtk_status_hbox = Gtk::HBox.new
      bus["/gtk/window/statusbar"].data = gtk_status_hbox
      gtk_status1 = Gtk::Statusbar.new
      gtk_status2 = Gtk::Statusbar.new
      bus["/gtk/window/statusbar/status1"].data = gtk_status1
      bus["/gtk/window/statusbar/status2"].data = gtk_status2
      gtk_status_hbox.pack_start(gtk_status1)
      gtk_status_hbox.pack_start(gtk_status2)
      gtk_table.attach(gtk_status_hbox,
                   # X direction            # Y direction
                   0, 1,                    3, 4,
                   Gtk::EXPAND | Gtk::FILL, Gtk::FILL,
                   0,      0)
      add(gtk_table)

      pane = Redcar::NotebookPane.new self
      @widgets_panes[pane.widget] = pane
      gtk_panes_box.add(pane.widget)

      @initial_show_widgets =
        [
         gtk_table,
         gtk_status_hbox,
         gtk_status1,
         gtk_status2,
         gtk_panes_box,
         #gtk_toolbar,
         gtk_edit_view,
         @gtk_menubar,
         pane.widget
        ]
    end

    def show_initial_widgets
      @initial_show_widgets.each {|w| w.show }
      show
    end

    # Sets the only active tab range to tab.class
    def update_tab_range(tab) #:nodoc:
      if tab
        Range.active.each do |range|
          if range < Redcar::Tab and
              range != tab.class
            Range.deactivate(range)
          end
        end
        unless Range.active.include? tab.class
          Range.activate(tab.class)
        end
        unless Range.active.include? Redcar::Tab
          Range.activate(Redcar::Tab)
        end
      else
        # there are no tabs
        Range.active.each do |range|
          if range <= Redcar::Tab and
            Range.deactivate(range)
          end
        end
      end
    end
  end
end

