module Redcar
  # A NotebookPane is a container for Tabs. Tabs can be 
  # dragged from one NotebookPane to another.
  #
  # Plugin authors should not create NotebookPanes by hand, rather
  # they should use Pane#split_horizontal and Window#panes to 
  # create and locate panes.
  class NotebookPane < Pane
    # The label_angle of the tabs in the Pane.
    attr_reader   :label_angle
    # The label_position of the tabs in the Pane.
    attr_reader   :label_position
    
    def self.load #:nodoc:
      Hook.register :new_tab
      Hook.register :close_tab
      Hook.register :focus_tab
    end
    
    # Do not call this directly.
    def initialize(window)
      super(window)#, :chrome => false)
      make_notebook
      connect_notebook_signals
      show_notebook
    end
    
    # Returns the Gtk::Notebook
    def gtk_widget
      @gtk_notebook
    end
    
    alias_method :notebook, :gtk_widget
    
    # Creates a new Tab in the Pane. tab_type should be
    # Redcar::Tab or child class. args are passed
    # on to tab_type#initialize.
    def new_tab(tab_type=EditTab, *args)
      if tab_type.singleton? and existing_instance = tab_type.instance
        return existing_instance
      end
      tab = tab_type.new(self, *args)
      add_tab(tab)
      Hook.trigger :new_tab, tab
      tab
    end
    
    # Return an array of all Tabs in this Pane.
    def tabs
      (0...@gtk_notebook.n_pages).map do |i|
        Tab.widget_to_tab[@gtk_notebook.get_nth_page(i)]
      end
    end
    
    # Return the active Tab in this Pane. Note that this may
    # not be the currently focussed Tab in the Window.
    def active_tab
      Tab.widget_to_tab[@gtk_notebook.get_nth_page(@gtk_notebook.page)]
    end
    
    # Move Tab tab to Pane dest_pane.
    def move_tab(tab, dest_pane)
      remove_tab(tab)
      dest_pane.add_tab(tab)
    end
    
    def add_tab(tab) #:nodoc:
      tab.label_angle = @label_angle
      @gtk_notebook.append_page(tab.gtk_nb_widget, tab.label)
      @gtk_notebook.set_tab_reorderable(tab.gtk_nb_widget, true)
      @gtk_notebook.set_tab_detachable(tab.gtk_nb_widget, true)
      @gtk_notebook.show_all
      @gtk_notebook.set_menu_label(tab.gtk_nb_widget, tab.menu_label)
      tab.pane = self
    end
    
    def focus_tab(tab) #:nodoc:
      if tab.pane == self
        @gtk_notebook.set_page(@gtk_notebook.page_num(tab.gtk_nb_widget))
        tab.gtk_nb_widget.grab_focus
      else
        raise "focussing tab in wrong pane"
      end
    end
    
    private
    
    def make_notebook
      @gtk_notebook = Gtk::Notebook.new
      @gtk_notebook.set_group_id 0
      @gtk_notebook.homogeneous = false
      @gtk_notebook.scrollable = true
      @gtk_notebook.enable_popup = true
    end
    
    def connect_notebook_signals
      @gtk_notebook.signal_connect("page-added") do |nb, gtk_widget, _, _|
        tab = Tab.widget_to_tab[gtk_widget]
        tab.label_angle = @label_angle
        tab.pane = self
        false
      end
      @gtk_notebook.signal_connect("switch-page") do |nb, _, page_num|
        @window.update_focussed_tab(Tab.widget_to_tab[nb.get_nth_page(page_num)])
        true
      end
    end
    
    def show_notebook
      @gtk_notebook.show_all
    end
    
    def remove_tab(tab)
      @gtk_notebook.remove(tab.gtk_nb_widget)
      tab.pane = nil
    end
    
    def label_angle=(angle)
      @label_angle = angle
      tabs.each do |tab|
        tab.label_angle = angle
      end
    end
    
    def label_position=(position)
      @label_position = position
      case position
      when :bottom
        @gtk_notebook.set_tab_pos(Gtk::POS_BOTTOM)
      when :left
        @gtk_notebook.set_tab_pos(Gtk::POS_LEFT)
      when :right
        @gtk_notebook.set_tab_pos(Gtk::POS_RIGHT)
      else
        @gtk_notebook.set_tab_pos(Gtk::POS_TOP)
      end
    end
  end
end
