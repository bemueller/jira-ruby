module JIRA
  module Resource
    class Watcher < User
      belongs_to :issue

      def self.endpoint_name
        'watchers'
      end

      # Overrides default behaviour due to nested resource.
      def url
        client.options[:rest_base_path] + '/issue/' + @issue_id + '/' + self.class.endpoint_name
      end

      # Removes user from watch list.
      #
      # Watchers are removed by a DELETE request on the nested resource
      # and a single username as URL parameter.
      # Will return false and print the response if the the request fails.
      def delete
        client.delete(url + '?username=' + @attrs['name'])
        @deleted = true
      rescue JIRA::HTTPError => exception
        puts ">>>>>>>>> Exception response: #{exception.response.body}"
        false
      end

      # Adds user to watch list.
      #
      # Watchers are added by POST request on the nested resource. POST body
      # contains only a single username.
      # Will raise a JIRA::HTTPError if the request fails (response is not
      # HTTP 2xx).
      def save!(username)
        client.post(url, username.to_json)
        @expanded = false
        true
      end
    end
  end
end
