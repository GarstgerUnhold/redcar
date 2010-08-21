module Redcar
  class Grammar
    module Default
      
      def word
        /^\w+$/
      end
      
      def comment
        "--"
      end
    end
  end
end
