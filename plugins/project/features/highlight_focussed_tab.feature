Feature: Highlight the File of the focussed tab in tree

  Scenario: Opening a file should reveal it in the tree
    Given I will choose "plugins/project/spec/fixtures/winter.txt" from the "open_file" dialog
    And I open a file
    Then there should be one edit tab
    And I should see "Wintersmith" in the edit tab
    And "winter.txt" should be selected in the project tree
