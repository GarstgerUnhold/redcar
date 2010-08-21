module Redcar
  class Grammar
    module Java
      
      def word
        /^\w+$/
      end
      
      def comment
        "//"
      end
    end
  end
end
