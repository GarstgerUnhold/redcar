
Then /^there should be #{FeaturesHelper::NUMBER_RE} (?:(\w+?)s?|tabs?) open$/ do |number, area_type|
  number = parse_number(number)
  if area_type
    if area_type =~ /Tab$/  
      Redcar.win.collect_tabs(Redcar.const_get(area_type)).length.should == number
    else area_type =~ /Pane$/
      Redcar.win.panes(Redcar.const_get(area_type)).length.should == number
    end
  else
    Redcar.win.tabs.length.should == number
  end
end

Then /^the title of the (\w+) should be "([^"]+)"$/ do |tab_type, title| # "
  tab = only(Redcar.win.collect_tabs(Redcar.const_get(tab_type)))
  tab.title.should == title
end
