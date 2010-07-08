
def escape_text(text)
  text.gsub("\\n", "\n").gsub("\\t", "\t")
end

def only_tab(tab_type, title=nil)
  tabs = Redcar.win.collect_tabs(Redcar.const_get(tab_type))
  if title
    tabs = tabs.select {|t| t.title == title}
  end
  only(tabs)
end

def only_pane(pane_type)
  panes = Redcar.win.panes(Redcar.const_get(pane_type))
  only(panes)
end

def only_area(area_type, title=nil)
  if area_type =~ /Tab$/
    area = only_tab(area_type, title)
  elsif area_type =~ /Pane$/
    area = only_pane(area_type)
  end
end

Then /^I should see #{FeaturesHelper::STRING_RE} in the (\w+)(?: "([^"]+)")?$/ do |text, area_type, title| # "
  text = parse_string(text)
  area = only_area(area_type)
  # p area
  # p area.visible_contents_as_string
  area.visible_contents_as_string.should include(escape_text(text))
end

Then /^I should not see #{FeaturesHelper::STRING_RE} in the (\w+)(?: "([^"]+)")?$/ do |text, area_type, title| 
  text = eval(text.inspect)
  area = only_area(area_type, title)
  area.visible_contents_as_string.should_not include(escape_text(text))
end

When /^I close the tab$/ do
  Redcar::CloseTab.new.do
end

When /^I save all the open tabs$/ do
  Redcar::SaveAllTabsCommand.new.do
end

Then /^the label of the (\w+) should say "([^"]+)"$/ do |tab_type, label|
  tab = only_tab(tab_type)
  tab.title.should == label
end

Then /^there should be #{FeaturesHelper::NUMBER_RE} ([A-Z]\w+)$/ do |num, tab_type|
  Redcar.win.collect_tabs(Redcar.const_get(tab_type)).length.should == parse_number(num)
end

Given /^there are TestTabs open "([^\"]*)"$/ do |tabnames|
  tabnames.split(",").map(&:strip).each {|name| Redcar.win.new_tab(Redcar::TestTab, name)}
end

Given /^I am looking at TestTab "([^\"]*)"$/ do |name|
  Redcar.win.tabs.find{|tab| tab.name == name}.focus
end

When /^I (right|left) click on the (\w+)Tab$/ do |button, tab_type| # 
  tab = only(Redcar.win.collect_tabs(Redcar.const_get(tab_type + "Tab")))
  widget = tab.gtk_tab_widget
  case button
  when "right"
    right_click_on(widget)
  when "left"
    left_click_on(widget)
  end
end

When /^I (right|left) click on the (\w+)Pane$/ do |button, pane_type| # 
  pane = only(Redcar.win.panes(Redcar.const_get(pane_type + "Pane")))
  case pane_type
  when "Project"
    widget = pane.gtk_widget.children.first
  else
    widget = pane.widget
  end
  case button
  when "right"
    right_click_on(widget)
  when "left"
    left_click_on(widget)
  end
end


Then /^I should be looking at the #{FeaturesHelper::ORDINAL_RE} EditTab$/ do |ordinal|
  num = parse_ordinal(ordinal) - 1
  Redcar.win.tabs[num].should == Redcar.tab
end

Then /^I should be looking at TestTab "([^\"]*)"$/ do |name|
  Redcar.tab.name.should == name
end
