module JIRA
  module Resource

    class WatcherFactory < JIRA::BaseFactory # :nodoc:
      # This method needs special handling as it has a default argument value
    end

    class Watcher < User
      belongs_to :issue

      def self.endpoint_name
        'watchers'
      end

      def url
        client.options[:rest_base_path] + '/issue/' + @issue_id + '/' + self.class.endpoint_name
      end

      def delete
        client.delete(url + '?username=' + @attrs['name'])
        @deleted = true
      rescue JIRA::HTTPError => exception
        puts ">>>>>>>>> Exception response: #{exception.response.body}"
        false
      end

      # Saves the specified resource attributes by sending either a POST or PUT
      # request to JIRA, depending on resource.new_record?
      #
      # Accepts an attributes hash of the values to be saved.  Will throw a
      # JIRA::HTTPError if the request fails (response is not HTTP 2xx).
      def save!(attrs)
        raise "Field 'name' is mandatory" unless attrs[:name]

        client.post(url, attrs[:name].to_json)
        @attrs.merge!(attrs.slice(:name))

        # reload watcher
        fetch(true)
        @expanded = false
        true
      end

      def set_attrs_from_response(response)
        unless response.body.nil? or response.body.length < 2
          json = self.class.parse_json(response.body)
          selected_watcher = json[self.class.endpoint_name].detect { |watcher| watcher['name'] == @attrs[:name] }
          set_attrs(selected_watcher)
        end
      end
    end

  end
end
