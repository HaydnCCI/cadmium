require "./form_set"

module Cadmium
  module Inflectors
    abstract class TenseInflector
      private property ambiguous : Array(String)
      private property plural_forms : FormSet
      private property singular_forms : FormSet
      private property custom_singular_forms : Array(Tuple(Regex, String))
      private property custom_plural_forms : Array(Tuple(Regex, String))

      private def initialize
        @ambiguous = [] of String
        @custom_plural_forms = [] of Tuple(Regex, String)
        @custom_singular_forms = [] of Tuple(Regex, String)
        @singular_forms = FormSet.new
        @plural_forms = FormSet.new
      end

      def pluralize(token)
        ize(token, plural_forms, custom_plural_forms)
      end

      def singularize(token)
        ize(token, singular_forms, custom_singular_forms)
      end

      def add_singular(pattern, replacement)
        custom_singular_forms.push({pattern, replacement})
      end

      def add_plural(pattern, replacement)
        custom_plural_forms.push({pattern, replacement})
      end

      def ize(token, form_set, custom_forms)
        restore_case = self.restore_case(token)
        restore_case.call(ize_regex(token, custom_forms) || ize_ambiguous(token) ||
                          ize_regulars(token, form_set) || ize_regex(token, form_set.regular_forms) || token)
      end

      def ize_ambiguous(token)
        if ambiguous.includes?(token.downcase)
          return token.downcase
        end
      end

      def ize_regulars(token, form_set)
        token = token.downcase
        if form_set.irregular_forms.has_key?(token) && form_set.irregular_forms[token]
          return form_set.irregular_forms[token]
        end
      end

      def ize_regex(token, forms)
        forms.each do |form|
          if token.match(form[0])
            return token.sub(form[0], form[1])
          end
        end
      end

      def add_form(singular_table, plural_table, singular, plural)
        singular = singular.downcase
        plural = plural.downcase
        plural_table[singular] = plural
        singular_table[plural] = singular
      end

      def add_irregular(singular, plural)
        add_form(singular_forms.irregular_forms, plural_forms.irregular_forms, singular, plural)
      end

      def restore_case(token)
        if token[0] == token[0].upcase
          if token[1]? && token[1] == token[1].downcase
            ->(token : String) { token.capitalize }
          else
            ->(token : String) { token.upcase }
          end
        else
          ->(token : String) { token.downcase }
        end
      end
    end
  end
end
