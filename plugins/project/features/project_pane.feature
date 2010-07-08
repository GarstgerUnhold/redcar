Feature: The Project Pane
  As a User
  I want to navigate through my projects easily

  Scenario: Open the project pane
    When I press "Ctrl+Shift+P"
    Then there should be one ProjectPane open

  Scenario: Shows the menu
    Given the ProjectPane is open
    When I right click on the ProjectPane
    Then I should see a menu with "Add Project Directory"

  Scenario: Add a project directory, adds directory, subdirectories and files
    Given the ProjectPane is open
    When I add the directory "plugins/project" to the ProjectPane
    Then I should see "project" in the ProjectPane
    And I should see "commands" in the ProjectPane   
    And I should see "plugin.rb" in the ProjectPane
    And I should not see "step_definitions" in the ProjectPane
    And I should not see "[dummy row]" in the ProjectPane

  Scenario: Remove a project directory
    Given the ProjectPane is open
    When I add the directory "plugins/project" to the ProjectPane
    And I remove the directory "plugins/project" from the ProjectPane
    Then I should not see "project" in the ProjectPane

  Scenario: Remove a project directory by giving a subdirectory
    Given the ProjectPane is open
    When I add the directory "plugins/project" to the ProjectPane
    And I remove the directory "plugins/project/spec" from the ProjectPane
    Then I should not see "project" in the ProjectPane

  Scenario: Open a subdirectory
    Given the ProjectPane is open
    And I have added the directory "plugins/project" to the ProjectPane
    When I open "features" in the ProjectPane
    Then I should see "step_definitions" in the ProjectPane
    And I should see "env.rb" in the ProjectPane
    And I should not see "[dummy row]" in the ProjectPane

  Scenario: Close a subdirectory
    Given the ProjectPane is open
    And I have added the directory "plugins/project" to the ProjectPane
    When I open "features" in the ProjectPane
    When I close "features" in the ProjectPane
    Then I should not see "step_definitions" in the ProjectPane

  Scenario: Should reload subdirectories
    Given the ProjectPane is open
    And I have added the directory "plugins/project" to the ProjectPane
    When I open "features" in the ProjectPane
    And I should not see "astoria.txt" in the ProjectPane
    And I close "features" in the ProjectPane
    And I create a file "astoria.txt" in the project plugin's features directory
    And I open "features" in the ProjectPane
    Then I should see "astoria.txt" in the ProjectPane
    And I cleanup the file "astoria.txt" in the project plugin's features directory

  Scenario: Opens a ProjectPane is one is required
    When I add the directory "plugins/project" to the ProjectPane
    Then there should be one ProjectPane open
    And I should see "project" in the ProjectPane


