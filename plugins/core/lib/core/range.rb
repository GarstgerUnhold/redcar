
module Redcar
  # Every Redcar::Command is valid inside one and only one 
  # Redcar::Range. Ranges include instances of:
  #
  #    Redcar::Window
  #    Redcar::Pane and subclasses
  #    Redcar::Tab and subclasses
  #    Redcar::EditView and subclasses
  #    Redcar::Speedbar and subclasses
  #
  # Commands in a Range are activated when that Range is
  # focussed, e.g. when the user clicks in an EditView or in
  # the ProjectPane.
  module Range
    mattr_accessor :active
    
    def self.activate(range)
      @commands ||= { }
      if @active.include? range
        true
      else
        @active << range
        activate_commands(@commands[range]||[])
      end
    end
    
    def self.deactivate(range)
      @commands ||= { }
      if @active.include? range
        @active.delete range
        deactivate_commands(@commands[range]||[])
      else
        true
      end
    end
    
    def self.activate_commands(commands)
      commands.each{ |c| c.in_range = true }
    end
    
    def self.deactivate_commands(commands)
      commands.each{ |c| c.in_range = false }
    end
    
    def self.register_command(range, command)
      if valid?(range)
        @commands ||= { }
        @commands[range] ||= []
        @commands[range] << command
      else
        raise "cannot register a command with an invalid "+
        "range: #{range}"
      end
    end
    
    def self.valid?(range)
      range_ancestors = range.ancestors.map(&:to_s)
      # TODO: fix this to not hardcode references to plugins
      range.is_a? Class and
      (range == Redcar::Window or
      range <= Redcar::Tab or
      range <= Redcar::Pane or 
      range_ancestors.include? "Redcar::EditView" or
      range_ancestors.include? "Redcar::Speedbar")
    end
  end
end
