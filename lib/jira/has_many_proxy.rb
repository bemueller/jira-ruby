#
# Whenever a collection from a has_many relationship is accessed, an instance
# of this class is returned.  This instance wraps the Array of instances in
# the collection with an extra build method, which allows new instances to be
# built on the collection with the correct properties.
#
# In practice, instances of this class behave exactly like an Array.
#
class JIRA::HasManyProxy

  attr_reader :target_class, :parent
  attr_accessor :collection

  def initialize(parent, target_class, collection = [])
    @parent       = parent
    @target_class = target_class
    @collection   = collection
  end

  # Builds an instance of this class with the correct parent.
  # For example, issue.comments.build(attrs) will initialize a
  # comment as follows:
  #
  #   JIRA::Resource::Comment.new(issue.client,
  #                               :attrs => attrs,
  #                               :issue => issue)
  def build(attrs = {})
    resource = target_class.new(parent.client, :attrs => attrs, parent.to_sym => parent)
    collection << resource
    resource
  end

  # Forces an HTTP request to fetch all instances of the target class that
  # are associated with the parent
  def all
    target_class.all(parent.client, parent.to_sym => parent)
  end

  # Adds more resources to relation.
  def add(*args)
    args.each do |argument|
      build.save(argument)
    end

    true
  end

  # Reduces the list of resources according the given criteria hash and returns a
  # new HasManyProxy relation.
  def where(criteria = {})
    selection = @collection.select { |item| recursive_compare(item.attrs, criteria) }

    self.class.new(@parent, @target_class, selection)
  end

  # Removes all resources of the HasManyProxy relation.
  def remove_all
    @collection.each do |resource|
      resource.delete
    end

    true
  end

  # Delegate any missing methods to the collection that this proxy wraps
  def method_missing(method_name, *args, &block)
    collection.send(method_name, *args, &block)
  end

  # Determines if the hash matches all criteria specified in another hash.
  # A criterion can accept multiple values by listing them in an array.
  #
  # Examples:
  #   recursive_compare({:foo => {:bar => 1}, :bla => 2}, {:bla => 2}) # => true
  #   recursive_compare({:foo => {:bar => 1}, :bla => 2}, {:bla => [1,2]}) # => true
  #   recursive_compare({:foo => {:bar => 1}, :bla => 2}, {:foo => {:bar => 1}}) # => true
  #   recursive_compare({:foo => {:bar => 1}, :bla => 2}, {:foo => {:bar => 2}}) # => false
  #   recursive_compare({:foo => {:bar => 1}, :bla => 2}, {:foo => {:bar => 2}, :bla => 2}) # => true
  def recursive_compare(hash, criteria)
    criteria.inject(true) do |parent, criterion|
      # check if criterion is still a nested hash
      if criterion[1].instance_of?(Hash)
        if hash.instance_of?(Hash)
          parent && recursive_compare(hash[criterion[0]], criterion[1])
        else
          # in this case the criteria hash is nested deeper than the origin hash
          false
        end
      else
        if criterion[1].instance_of?(Array)
          # if the criterion contains multiple value, check if one of them matches
          parent && criterion[1].include?(hash[criterion[0]])
        else
          parent && hash[criterion[0]] == criterion[1]
        end
      end
    end
  end
  private :recursive_compare
end
