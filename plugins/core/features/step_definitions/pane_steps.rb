
Then /^there should be #{FeaturesHelper::NUMBER_RE} panes?$/ do |num|
  Redcar.win.panes.length.should == parse_number(num)
end

def pane_tree(widget, indent=0, str="")
  str << " "*indent + widget.class.to_s + "\n"
  if widget.respond_to?(:children)
    widget.children.each do |gtk_child|
      if pane = Redcar.win.widgets_panes[gtk_child]
        str << " "*(indent+2) + pane.class.name + "\n"
      else
        pane_tree(gtk_child, indent+2, str)
      end
    end
  end
  str
end

Then /^there should be panes like$/ do |tree|
  pane_tree(bus["/gtk/window/panes_container"].data).chomp.should == tree
end
