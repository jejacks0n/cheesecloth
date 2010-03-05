module Cheesecloth
  class SimpleBuilder
    
  end
end

#module ActsAsFilterable
#  module FormHelper
#    def self.included(base)
#      base.send(:include, InstanceMethods)
#    end
#
#    module InstanceMethods
#      def filter_form_for(name_or_array, options = {}, &block)
#        name = name_from_name_or_array(name_or_array)
#        path = path_from_name_or_array(name_or_array, options)
#
#        form_for(name, {
#          :url => path,
#          :html => {:class => "filter", :id => "filter_#{name}", :method => :get}.merge(options[:html] || {})
#        }.merge(options), &block)
#      end
#
#      def remote_filter_form_for(name_or_array, options = {}, &block)
#        name = name_from_name_or_array(name_or_array)
#        path = path_from_name_or_array(name_or_array, options)
#
#        observer = options.delete(:observer)
#
#        remote_form_for(name,{
#          :url => path,
#          :method => :get,
#          :html => {:class => "filter", :id => "filter_"}.merge(options[:html] || {})
#        }.merge(options), &block)
#
#        unless observer.nil?
#          concat observe_field("#{name}_#{observer}", :frequency => 0.5, :url => path, :with => "Form.serialize('filter_#{name}')", :method => :get), block.binding
#        end
#      end
#
#      private
#      def name_from_name_or_array(name_or_array)
#        case name_or_array
#        when Array
#          name_or_array.last
#        else
#          name_or_array
#        end
#      end
#
#      def path_from_name_or_array(name_or_array, options)
#        unless options[:url].blank?
#          options[:url]
#        else
#          case name_or_array
#          when Array
#            path_helper = name_or_array.map { |s| s.is_a?(Symbol) ? s.to_s : s.class.to_s.downcase }.join('_').pluralize
#            path_args = name_or_array[0..-2]
#            send("#{path_helper}_path", *path_args)
#          else
#            send("#{name_or_array.to_s.pluralize}_path")
#          end
#        end
#      end
#    end
#  end
#end
