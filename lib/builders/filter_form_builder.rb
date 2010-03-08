module Cheesecloth
  class FilterFormBuilder < ActionView::Helpers::FormBuilder
    def fields(options = {})
      object = object.blank? ? @object_name.to_s.titleize.singularize.constantize : object
      options_for_select = [['All Columns', 'all']] + object.filterable_fields.collect { |field| [field.titleize, field] }

      @template.select_tag("filter[#{filter_table_name}][fields]", @template.options_for_select(options_for_select), options)
    end

    def terms(options = {})
      @template.text_field_tag("filter[#{filter_table_name}][terms]", filter_params(:terms), options)
    end

    def methods(options = {})
      @template.select_tag("filter[#{filter_table_name}][fields]", [['Any', 'any'], ['All', 'all'], ['Exact Phrase', 'exact'], ['All in Order', 'all_in_order']], options)
    end

    def submit(options = {})
      @template.submit_tag('Apply', options)
    end

    def current_filters
      return nil unless filter_params(:fields)
      {
        :fields => filter_params(:fields).to_a.map { |field| field.titleize }.to_sentence,
        :terms => filter_params(:terms)
      }
    end

    private

    def filter_params(field)
      params = @template.params['filter']
      return nil unless params
      params[filter_table_name] ? params[filter_table_name][field.to_s] : nil
    end

    def filter_table_name
      @table_name ||= object_name.to_s.pluralize
    end
  end
end
