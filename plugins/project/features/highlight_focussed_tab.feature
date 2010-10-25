Feature: Highlight the File of the focussed tab in tree

  Scenario: Opening a file should reveal it in the tree
    Given I open a "/test1" as a subproject of the current directory
    And I will choose "myproject/test1/a.txt" from the "open_file" dialog
    And I open a file
    Then there should be one edit tab
    And I should see "Wintersmith" in the edit tab
    And "winter.txt" should be selected in the project tree
