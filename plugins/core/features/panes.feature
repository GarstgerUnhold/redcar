Feature: Multiple panes
  As a user
  I want to split up my workspace into multiple areas
  In order to have all aspects of my project visible at a glance

  Scenario: Single pane
    Then there should be 1 pane

  Scenario: Split Horizontal
    When I press "Ctrl+2"
    Then there should be panes like
      """
      Gtk::HBox
        Gtk::VPaned
          Redcar::NotebookPane
          Redcar::NotebookPane
      """

  Scenario: Split Vertical
    When I press "Ctrl+3"
    Then there should be panes like
      """
      Gtk::HBox
        Gtk::HPaned
          Redcar::NotebookPane
          Redcar::NotebookPane
      """

  Scenario: Split Horizontal then Vertical
    When I press "Ctrl+2"
    And I press "Ctrl+3"
    Then there should be panes like
      """
      Gtk::HBox
        Gtk::VPaned
          Gtk::HPaned
            Redcar::NotebookPane
            Redcar::NotebookPane
          Redcar::NotebookPane
      """

  Scenario: Split Horizontal then Unify
    When I press "Ctrl+2"
    And I press "Ctrl+1"
    Then there should be 1 pane

  Scenario: Split Vertical then Unify
    When I press "Ctrl+3"
    And I press "Ctrl+1"
    Then there should be 1 pane

  Scenario: Unify collects tabs
    When I press "Ctrl+T"
    When I press "Ctrl+3"
    And I press "Ctrl+1"
    Then there should be 1 pane
    And there should be 1 EditTab

  Scenario: If there is one pane, it must be a NotebookPane
    When I press "Ctrl+Shift+P"
    And I press "Ctrl+2"
    And I press "Ctrl+3"
    And I press "Ctrl+1"
    Then there should be panes like
      """
      Gtk::HBox
        Redcar::NotebookPane
      """
