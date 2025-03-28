require "rails_helper"

RSpec.describe Filtered, type: :model do
  with_model :BasicFilterableTestModel, scope: :all do
    table do |t|
      t.string :name
      t.integer :favorite_number
    end

    model do
      include SnFilterable::Filterable

      BasicFilterableTestModel::FILTER_SCOPE_MAPPINGS = { # rubocop:disable RSpec/LeakyConstantDeclaration
        "name": :filter_by_name,
        "favorite_number": :filter_by_favorite_number
      }.freeze

      BasicFilterableTestModel::SORT_SCOPE_MAPPINGS = { # rubocop:disable RSpec/LeakyConstantDeclaration
        "name": :sort_by_name,
        "favorite_number": :sort_by_favorite_number
      }.freeze

      scope :filter_by_name, ->(name) { where("name = ?", name) }
      scope :filter_by_favorite_number, ->(favorite_number) { where("favorite_number = ?", favorite_number) }

      scope :sort_by_name, -> { order :name }
      scope :sort_by_created_at, -> { order :created_at }
    end
  end

  subject { filtered }

  let(:filtered) { BasicFilterableTestModel.filter(params: ActionController::Parameters.new) }

  describe "#active_filters?" do
    it "returns false when no filters are active" do
      expect(filtered.active_filters?).to eq(false)
    end

    it "returns true when filters are active" do
      filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new({ filter: { name: "test" } }))

      expect(filtered.active_filters?).to eq(true)
    end
  end

  describe "#set_filter_url" do
    it "creates a valid url when it has no parameters" do
      expected_url = "/?filter%5Bname%5D=test"
      actual_url = filtered.set_filter_url("/", "name", "test")

      expect(actual_url).to eq(expected_url)
    end

    it "creates a valid url when there is a conflicting filter" do
      expected_url = "/?filter%5Bname%5D=test"
      actual_url = filtered.set_filter_url("/?filter%5Bname%5D=123", "name", "test")

      expect(actual_url).to eq(expected_url)
    end

    it "creates a valid url when there is one filter" do
      expected_url = "/?filter%5Bname%5D=test"
      actual_url = filtered.set_filter_url("/?filter%5Bfavorite_number%5D=123", "name", "test")

      expect(actual_url).to eq(expected_url)
    end

    it "creates a valid url when there are multiple filters" do
      expected_url = "/?filter%5Bname%5D=test"
      actual_url = filtered.set_filter_url("/?filter%5Bfavorite_number%5D=123&filter%5Bcreated_at%5D=897", "name", "test")

      expect(actual_url).to eq(expected_url)
    end
  end

  describe "#add_filter_url" do
    it "creates a valid url when there are no filters" do
      expected_url = "/?filter%5Bname%5D=test"
      actual_url = filtered.add_filter_url("/", "name", "test")

      expect(actual_url).to eq(expected_url)
    end

    it "creates a valid url when there is a conflicting filter" do
      actual_url = filtered.add_filter_url("/?filter%5Bname%5D=123", "name", "test")

      expect(actual_url).to include("filter%5Bname%5D=test")
    end

    it "creates a valid url when there is one filter" do # rubocop:disable RSpec/MultipleExpectations
      actual_url = filtered.add_filter_url("/?filter%5Bfavorite_number%5D=123", "name", "test")

      expect(actual_url).to include("filter%5Bfavorite_number%5D=123")
      expect(actual_url).to include("filter%5Bname%5D=test")
    end

    it "creates a valid url when there are multiple filters" do # rubocop:disable RSpec/MultipleExpectations
      actual_url = filtered.add_filter_url("/?filter%5Bfavorite_number%5D=123&filter%5Bcreated_at%5D=897", "name", "test")

      expect(actual_url).to include("filter%5Bfavorite_number%5D=123")
      expect(actual_url).to include("filter%5Bcreated_at%5D=897")
      expect(actual_url).to include("filter%5Bname%5D=test")
    end
  end

  describe "#remove_filter_url" do
    it "creates a valid url when it has no parameters" do
      expected_url = "/"
      actual_url = filtered.remove_filter_url("/", "name")

      expect(actual_url).to eq(expected_url)
    end

    it "creates a valid url when there is a matching filter" do
      expected_url = "/"
      actual_url = filtered.remove_filter_url("/?filter%5Bname%5D=123", "name")

      expect(actual_url).to eq(expected_url)
    end

    it "creates a valid url when there are no matching filters" do
      expected_url = "/?filter%5Bfavorite_number%5D=123"
      actual_url = filtered.remove_filter_url("/?filter%5Bfavorite_number%5D=123", "name")

      expect(actual_url).to eq(expected_url)
    end

    it "creates a valid url when there is a matching and multiple filters" do # rubocop:disable RSpec/MultipleExpectations
      actual_url = filtered.remove_filter_url("/?filter%5Bname%5D=123&filter%5Bfavorite_number%5D=123&filter%5Bcreated_at%5D=897", "name")

      expect(actual_url).to include("filter%5Bfavorite_number%5D=123")
      expect(actual_url).to include("filter%5Bcreated_at%5D=897")
      expect(actual_url).not_to include("filter%5Bname%5D=test")
    end
  end

  describe "#remove_sub_filter_url" do
    it "creates a valid url when it has no parameters" do
      expected_url = "/"
      actual_url = filtered.remove_sub_filter_url("/", "name", "abc")

      expect(actual_url).to eq(expected_url)
    end

    it "creates a valid url when there is a matching filter" do
      expected_url = "/"
      actual_url = filtered.remove_sub_filter_url("/?filter%5Bname%5D%5B%5D=123", "name", "123")

      expect(actual_url).to eq(expected_url)
    end

    it "creates a valid url when there are no matching filters" do
      expected_url = "/?filter%5Bfavorite_number%5D%5B%5D=123"
      actual_url = filtered.remove_sub_filter_url("/?filter%5Bfavorite_number%5D%5B%5D=123", "favorite_number", "456")

      expect(actual_url).to eq(expected_url)
    end

    it "creates a valid url when there is a matching and multiple filters" do # rubocop:disable RSpec/MultipleExpectations
      actual_url = filtered.remove_sub_filter_url("/?filter%5Bname%5D%5B%5D=abc&filter%5Bname%5D%5B%5D=def&filter%5Bname%5D%5B%5D=ghi", "name", "abc")

      expect(actual_url).not_to include("filter%5Bname%5D%5B%5D=abc")
      expect(actual_url).to include("filter%5Bname%5D%5B%5D=def")
      expect(actual_url).to include("filter%5Bname%5D%5B%5D=ghi")
    end
  end

  describe "#clear_filter_url" do
    it "creates a valid url when it has no parameters" do
      expected_url = "/"
      actual_url = filtered.clear_filter_url("/")

      expect(actual_url).to eq(expected_url)
    end

    it "creates a valid url when there are filters" do
      expected_url = "/"
      actual_url = filtered.clear_filter_url("/?filter%5Bname%5D=test&filter%5Babc%5D=123")

      expect(actual_url).to eq(expected_url)
    end

    it "creates a valid url when there is sorting" do
      expected_url = "/?sort=name&order=desc"
      actual_url = filtered.clear_filter_url("/?sort=name&order=desc")

      expect(actual_url).to eq(expected_url)
    end

    it "creates a valid url when there is sorting and filters" do
      expected_url = "/?sort=name&order=desc"
      actual_url = filtered.clear_filter_url("/?filter%5Bname%5D=test&filter%5Babc%5D=123&sort=name&order=desc")

      expect(actual_url).to eq(expected_url)
    end
  end

  describe "#clear_sort_url" do
    it "creates a valid url when it has no parameters" do
      expected_url = "/"
      actual_url = filtered.clear_sort_url("/")

      expect(actual_url).to eq(expected_url)
    end

    it "creates a valid url when there is sorting" do
      expected_url = "/"
      actual_url = filtered.clear_sort_url("/?sort=name&order=desc")

      expect(actual_url).to eq(expected_url)
    end

    it "creates a valid url when there are filters" do
      expected_url = "/?filter%5Bname%5D=test&filter%5Babc%5D=123"
      actual_url = filtered.clear_sort_url("/?filter%5Bname%5D=test&filter%5Babc%5D=123")

      expect(actual_url).to eq(expected_url)
    end

    it "creates a valid url when there is sorting and filters" do
      expected_url = "/?filter%5Bname%5D=test&filter%5Babc%5D=123"
      actual_url = filtered.clear_sort_url("/?filter%5Bname%5D=test&filter%5Babc%5D=123&sort=name&order=desc")

      expect(actual_url).to eq(expected_url)
    end
  end

  describe "#clear_all_url" do
    it "creates an empty url when it has no parameters" do
      expected_url = "/"
      actual_url = filtered.clear_all_url("/")

      expect(actual_url).to eq(expected_url)
    end

    it "creates an empty url when there is sorting" do
      expected_url = "/"
      actual_url = filtered.clear_all_url("/?sort=name&order=desc")

      expect(actual_url).to eq(expected_url)
    end

    it "creates an empty url when there are filters" do
      expected_url = "/"
      actual_url = filtered.clear_all_url("/?filter%5Bname%5D=test&filter%5Babc%5D=123")

      expect(actual_url).to eq(expected_url)
    end

    it "creates an empty url when there is sorting and filters" do
      expected_url = "/"
      actual_url = filtered.clear_all_url("/?filter%5Bname%5D=test&filter%5Babc%5D=123&sort=name&order=desc")

      expect(actual_url).to eq(expected_url)
    end
  end

  describe "#sort_url" do
    it "returns the correct parameters when a block is given" do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
      filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new({ sort: "name" }))

      expected_url = "/?sort=name&order=desc"
      expected_state = :asc

      filtered.sort_url("/", "name") do |actual_url, actual_state|
        expect(actual_url).to eq(expected_url)
        expect(actual_state).to eq(expected_state)
      end
    end

    it "returns the correct parameters when a return value is expected" do
      filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new({ sort: "name" }))

      expected_result = ["/?sort=name&order=desc", :asc]
      actual_result = filtered.sort_url("/", "name")

      expect(actual_result).to eq(expected_result)
    end

    it "creates a url with sorting when given no parameters" do
      expected_result = ["/?sort=name", nil]
      actual_result = filtered.sort_url("/", "name")

      expect(actual_result).to eq(expected_result)
    end

    it "creates a valid descending url when sorting in ascending order" do
      filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new({ sort: "name", order: "asc" }))

      expected_result = ["/?sort=name&order=desc", :asc]
      actual_result = filtered.sort_url("/", "name")

      expect(actual_result).to eq(expected_result)
    end

    it "creates a valid ascending url when sorting in descending order" do
      filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new({ sort: "name", order: "desc" }))

      expected_result = ["/?sort=name&order=asc", :desc]
      actual_result = filtered.sort_url("/", "name")

      expect(actual_result).to eq(expected_result)
    end
    
    it "includes extra_params in the generated URL" do
      filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new({ sort: "name" }), extra_params: { "tab" => "active", "view" => "list" })

      actual_result = filtered.sort_url("/", "name")
      url = actual_result[0]
      state = actual_result[1]

      expect(state).to eq(:asc)
      expect(url).to include("sort=name")
      expect(url).to include("order=desc")
      expect(url).to include("tab=active")
      expect(url).to include("view=list")
    end
    
    it "properly merges extra_params with existing URL parameters" do
      filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new({ sort: "name" }), extra_params: { "tab" => "active" })

      actual_result = filtered.sort_url("/?existing=param", "name")
      url = actual_result[0]
      state = actual_result[1]

      expect(state).to eq(:asc)
      expect(url).to include("existing=param")
      expect(url).to include("sort=name")
      expect(url).to include("order=desc")
      expect(url).to include("tab=active") 
    end
  end
end
