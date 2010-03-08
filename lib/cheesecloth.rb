# coding: utf-8
require 'builders/filter_form_builder'

# to test {:filter => {:users => .. }
# {:method => 'any', :terms => ['first', 'second'], :fields => 'all'}
# {:method => 'any', :terms => 'first second',      :fields => 'all'}
# {:method => 'any', :terms => 'first', :fields => ['first_name', 'last_name']}
# {:method => 'any', :terms => 'first', :fields => 'first_name last_name'}
# {:method => 'all', :terms => ['first', 'second'], :fields => 'all'}
# {:method => 'all', :terms => 'first second', :fields => 'all'}
# {:method => 'all', :terms => 'first', :fields => 'first_name'}
# {:method => 'all', :terms => 'first', :fields => ['first_name', 'last_name']}
# {:method => 'exact', :terms => ['first', 'second'], :fields => 'all'}
# {:method => 'exact', :terms => 'first second', :fields => 'all'}
# {:method => 'exact', :terms => 'first second', :fields => 'first_name'}
# {:method => 'exact', :terms => 'first second', :fields => ['first_name', 'last_name']}
# {:method => 'all_in_order', :terms => ['first', 'second'], :fields => 'all'}
# {:method => 'all_in_order', :terms => 'first second', :fields => 'all'}
# {:method => 'all_in_order', :terms => 'first second', :fields => 'first_name'}
# {:method => 'all_in_order', :terms => 'second first', :fields => 'first_name'}
# {:method => 'all_in_order', :terms => 'second first', :fields => ['first_name', 'last_name']}

module Cheesecloth

  #
  #
  #
  #
  #
  module FilterFormHelper

    @@builder = ::Cheesecloth::FilterFormBuilder
    mattr_accessor :builder

    def filter_form_for(name, options = {}, &proc)
      raise ArgumentError, "Missing block" unless block_given?

      options[:html] ||= {}
      options[:html][:class] = add_class(options[:html][:class], 'filter-form')
      options[:html][:id] ||= "#{name.to_s.underscore}_filter"
      options[:html][:method] = :get

      form_for(name, {:builder => options.delete(:builder) || @@builder}.merge(options), &proc)
    end

    def add_class(classnames, classname)
      out = (classnames.is_a?(String) ? classnames.split(' ') : []) << classname
      out.join(' ')
    end

  end

  module ActiveRecordExtensions

    FILTER_METHODS = [:any, :all, :all_in_order, :exact]

    #
    #
    #
    # To get more details on the configuration options, check the FilterableConfiguration class that's below.
    #
    # === Example
    #   filterable_fields do
    #     only :first_name, :last_name, :login
    #     default_method :any
    #     allow_scopes :with_role
    #   end
    def filterable_fields(&config_block)
      cattr_accessor :filterable_fields, :filterable_scopes, :default_filter_method, :default_filter_options

      # make all columns filterable, incase only or except aren't called in the configuration block
      self.filterable_fields = column_names.map { |column_name| column_name.to_s }

      FilterableConfiguration.new(self).instance_eval(&config_block)
      self.filterable_fields.collect!{ |field| field.to_s }

      self.default_filter_method ||= :any
      self.default_filter_options ||= {}
    end

    class FilterableConfiguration
      def initialize(target)
        @target = target
      end

      # Provide fields that are filterable in the configuration block.
      #
      # *Note*: If +only+ or +except+ aren't called from within the configuration block, all fields will be filterable.
      #
      # === Example
      #   only :last_name, :email_address
      def only(*args)
        @target.filterable_fields = args
      end

      # Provide fields that are not to be filterable, with the default list being all fields.
      #
      # *Note*: If +only+ or +except+ aren't called from within the configuration block, all fields will be filterable.
      #
      # === Example
      #   except :id, :password
      def except(*args)
        @target.filterable_fields - args
      end

      # Provide named scopes that can be chained together to provide additional filtering conditions.  You can then
      # provide an interface that gives options for a given scope.  For example, using +with_role+ named_scope for Users
      # you may want to give a select menu or checkboxes of the different roles.
      #
      # These named_scopes will be chained for you (passing a string or array) when the filtered_from named scope is
      # called.
      #
      # === Example
      #   scopes :with_role, :created_before
      def allow_scopes(*args)
        @target.filterable_scopes = args
      end

      # Provide the default filter method.
      #
      # === Available methods
      # [:any]
      #   Returns records that match any of words provided in the terms (split by spaces)
      # [:all]
      #   Returns records that contain all of the words provided
      # [:all_in_order]
      #   Returns records that contain all the words provided, in order
      # [:exact]
      #   Returns records that contain an exact match of the string provided
      #
      # === Example
      #   default_method :any, :allowed => [:any, :all, :all_in_order]
      def default_method(*args)
        options = args.extract_options!
        method = args.shift || :any

        @target.default_filter_method = method
        @target.default_filter_options = options
      end
    end

    # The filtered_from method returns a named_scope object, or an anonymous scope if no conditions are needed, which
    # makes it behave as though it's a named_scope.  So you can use it like, and have all the benefits of, named_scopes.
    #
    # In the controller for example:
    #
    # +Users.filtered_from(params).paginate :page => params[:page], :per_page => 2+
    #
    # The params are expected to be in a specific style:
    # filter[users][fields]=array or string(separated with spaces -- or "all")
    # filter[users][method]=string [any, all, all_in_order, exact]
    # filter[users][terms]=array or string(separated with spaces)
    #
    # eg. filter[users][fields]=first_name last_name&filter[users][terms]=Jeremy
    #
    # Which will generate the conditions hash which more or less turns into this WHERE clause:
    #
    # +"WHERE (LOWER(users.first_name) LIKE '%jeremy%' OR LOWER(users.last_name) LIKE '%jeremy%'))"+
    #
    # The params can also contain user definded named_scopes that expect a string (or array, I would assume)
    #
    # eg. filter[users][with_role]=admin or filter[users][with_role][]=string1&filter[users][with_role][]=string2
    #
    # These can be used in conjunction with the method outlined above, but there is no interface bundled that creates
    # an interface for this.
    def filtered_from(params)
      scope = self.scoped({})
      return scope unless params.include?(:filter) and params[:filter][self.table_name.to_sym]

      options = params[:filter][self.table_name.to_sym]
      method = filter_method_from_options(options)
      terms = filter_terms_from_options(options, method)
      fields = filter_fields_from_options(options)
      scopes = filter_scopes_from_options(options)

      return scope if fields.blank? or terms.compact.blank?

      conditions = []
      terms.each do |term|
        value = term.downcase
        fields.each { |field| conditions << ["LOWER(#{table_name}.#{field}) LIKE ?", "%#{value}%"] }
      end

      conditions = conditions.compact.unzip
      if conditions.length > 1 && conditions[0] = conditions[0].join((method != :all) ? ' OR ' : ' AND ')
        scope = self.scoped(:conditions => (conditions.empty? ? nil : conditions.flatten))
      end
      ret = scopes.inject(scope) { |acc, scope_and_value|
        acc.send(scope_and_value[0].to_sym, scope_and_value[1])
      }
      ret
    end

    def filter_method_from_options(options)
      options[:method].present? && FILTER_METHODS.include?(options[:method].to_sym) ? options[:method].to_sym : self.default_filter_method
    end

    def filter_terms_from_options(options, method)
      if options[:terms].is_a?(Array) && method == :exact
        [options[:terms].join(' ')]
      elsif method == :exact
        [options[:terms]]
      elsif method == :all_in_order
        [options[:terms].split(' ').join('%')]
      else
        options[:terms].split(' ')
      end
    end

    def filter_fields_from_options(options)
      return self.filterable_fields if options[:fields] == 'all'
      fields = if options[:fields].is_a?(Array)
        options[:fields]
      else
        options[:fields].split(' ')
      end
      fields.reject{ |field| !self.filterable_fields.include?(field.to_s) }
    end

    def filter_scopes_from_options(options)
      options.reject { |option, value| [:fields, :terms, :method].include?(option) || !self.filterable_scopes.include?(option.to_sym) }
    end
  end
end

ActionController::Base.helper Cheesecloth::FilterFormHelper
ActiveRecord::Base.extend Cheesecloth::ActiveRecordExtensions
