module Redcar
  class Grammar
    module Ruby
      
      def word
        /^(\w)+(\?|\!)?$/
      end
      
      def comment
        "#"
      end
    end
  end
end
