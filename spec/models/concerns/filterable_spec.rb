require "rails_helper"

RSpec.describe SnFilterable, type: :model do  # rubocop:disable RSpec/MultipleDescribes
  with_model :BasicFilterableTestModel, scope: :all do
    table do |t|
      t.string :name
      t.integer :favorite_number
    end

    model do
      include SnFilterable::Filterable

      BasicFilterableTestModel::FILTER_SCOPE_MAPPINGS = { # rubocop:disable RSpec/LeakyConstantDeclaration
        "name": :filter_by_name,
        "favorite_number": :filter_by_favorite_number,
        "search": :search_by_name
      }.freeze

      BasicFilterableTestModel::SORT_SCOPE_MAPPINGS = { # rubocop:disable RSpec/LeakyConstantDeclaration
        "name": :sort_by_name,
        "favorite_number": :sort_by_favorite_number
      }.freeze

      scope :filter_by_name, ->(name) { where("name = ?", name) }
      scope :filter_by_favorite_number, ->(favorite_number) { where("favorite_number = ?", favorite_number) }

      scope :sort_by_name, -> { order :name }
      scope :sort_by_favorite_number, -> { order :favorite_number }
      scope :search_by_name, ->(search) { where("name like ?", "%#{search}%")}
    end
  end

  with_model :EmptyFilterableTestModel, scope: :all do
    table do |t|
      t.string :name
      t.timestamps
    end

    model do
      include SnFilterable::Filterable
    end
  end

  with_model :FilterOnlyFilterableTestModel, scope: :all do
    table do |t|
      t.string :name
      t.timestamps
    end

    model do
      include SnFilterable::Filterable

      FilterOnlyFilterableTestModel::FILTER_SCOPE_MAPPINGS = { # rubocop:disable RSpec/LeakyConstantDeclaration
        "name": :filter_by_name
      }.freeze

      scope :filter_by_name, ->(name) { where("name = ?", name) }
    end
  end

  with_model :SortOnlyFilterableTestModel, scope: :all do
    table do |t|
      t.string :name
      t.timestamps
    end

    model do
      include SnFilterable::Filterable

      SortOnlyFilterableTestModel::SORT_SCOPE_MAPPINGS = { # rubocop:disable RSpec/LeakyConstantDeclaration
        "name": :sort_by_name
      }.freeze

      scope :sort_by_name, -> { order :name }
    end
  end

  before do
    create_list(:basic_filterable_test_model, 10)
    create_list(:empty_filterable_test_model, 10)
    create_list(:filter_only_filterable_test_model, 10)
    create_list(:sort_only_filterable_test_model, 10)
  end

  it "can filter with no scope mappings" do
    EmptyFilterableTestModel.filter(
      params: ActionController::Parameters.new
    )
  end

  context "with all scope mappings" do
    let(:target_user) { BasicFilterableTestModel.first }
    let(:non_target_user) { BasicFilterableTestModel.last }

    it "can filter with no params" do
      expected_items = BasicFilterableTestModel.where(nil).to_a

      filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new)

      expect(filtered.items.to_a).to match_array(expected_items)
    end

    it "can filter with a single filter param" do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
      all_items = BasicFilterableTestModel.where(nil)
      expected_items = BasicFilterableTestModel.where("favorite_number = ?", target_user.favorite_number)

      filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new({ filter: { favorite_number: target_user.favorite_number } }))

      expect(filtered.items).to match_array(expected_items)
      expect(filtered.items).not_to match_array(all_items)
      expect(filtered.items).to include(target_user)
      expect(filtered.items).not_to include(non_target_user)
    end

    it "can filter with multiple filter params" do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
      all_items = BasicFilterableTestModel.where(nil)
      expected_items = BasicFilterableTestModel.where("favorite_number = ? AND name = ?", target_user.favorite_number, target_user.name)

      filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new({ filter: { favorite_number: target_user.favorite_number, name: target_user.name } }))

      expect(filtered.items).to match_array(expected_items)
      expect(filtered.items).not_to match_array(all_items)
      expect(filtered.items).to include(target_user)
      expect(filtered.items).not_to include(non_target_user)
    end

    it "can sort with missing order params" do
      expected_items = BasicFilterableTestModel.order("favorite_number ASC").map(&:favorite_number)

      filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new({ sort: "favorite_number" }))

      expect(filtered.items.map(&:favorite_number)).to eq(expected_items)
    end

    it "can sort with ascending order params" do
      expected_items = BasicFilterableTestModel.order("favorite_number ASC").map(&:favorite_number)

      filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new({ sort: "favorite_number", order: "asc" }))

      expect(filtered.items.map(&:favorite_number)).to eq(expected_items)
    end

    it "can sort with descending order params" do
      expected_items = BasicFilterableTestModel.order("favorite_number DESC").map(&:favorite_number)

      filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new({ sort: "favorite_number", order: "desc" }))

      expect(filtered.items.map(&:favorite_number)).to eq(expected_items)
    end

    it "will not sort when order is invalid" do
      expected_items = BasicFilterableTestModel.order(nil).map(&:favorite_number)

      filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new({ sort: "favorite_number", order: "both_asc_and_desc" }))

      expect(filtered.items.map(&:favorite_number)).to eq(expected_items)
    end

    it "can sort using a string default order" do
      expected_items = BasicFilterableTestModel.order("favorite_number ASC").map(&:favorite_number)

      filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new, default_sort: "favorite_number")

      expect(filtered.items.map(&:favorite_number)).to eq(expected_items)
    end

    it "can sort using an array default order" do
      expected_items = BasicFilterableTestModel.order("favorite_number DESC").map(&:favorite_number)

      filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new, default_sort: ["favorite_number", :desc])

      expect(filtered.items.map(&:favorite_number)).to eq(expected_items)
    end

    it "will throw when default order is invalid" do
      expect do
        BasicFilterableTestModel.filter(params: ActionController::Parameters.new, default_sort: 156)
      end.to raise_error TypeError
    end

    it "can search by keywords" do
      all_items = BasicFilterableTestModel.where(nil)
      expected_items = [all_items.first.name]

      filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new({ filter: { search: target_user.name } }))

      expect(filtered.items.map(&:name)).to eq(expected_items)
    end

    it "can search with other params" do
      expected_items = []

      filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new({ filter: { search: target_user.name, favorite_number: target_user.favorite_number + 1, order: "desc" } }))

      expect(filtered.items.map(&:name)).to eq(expected_items)
    end

    describe "pagination" do
      it "paginates when enabled" do
        items_per_page = 2
        filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new({ per: items_per_page }), pagination_enabled: true)

        expect(filtered.items.size).to eq(items_per_page)
      end

      it "can have pagination removed" do
        expected_size = BasicFilterableTestModel.where(nil).size
        filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new({ per: 2 }), pagination_enabled: false)

        expect(filtered.items.size).to eq(expected_size)
      end
    end
  end

  context "with no scope mappings" do
    it "can filter with no params" do
      FilterOnlyFilterableTestModel.filter(
        params: ActionController::Parameters.new
      )
    end

    it "can filter with an invalid filter param" do
      FilterOnlyFilterableTestModel.filter(
        params: ActionController::Parameters.new({ filter: { filternotexists: "John Smith" } })
      )
    end

    it "can filter with an invalid sort param" do
      FilterOnlyFilterableTestModel.filter(
        params: ActionController::Parameters.new({ sort: "invalidsortingkey" })
      )
    end
  end

  context "with only filter scope mappings" do
    it "can filter with no params" do
      FilterOnlyFilterableTestModel.filter(
        params: ActionController::Parameters.new
      )
    end

    it "can filter with a valid filter param" do
      FilterOnlyFilterableTestModel.filter(
        params: ActionController::Parameters.new({ filter: { name: "John Smith" } })
      )
    end

    it "can filter with an invalid filter param" do
      FilterOnlyFilterableTestModel.filter(
        params: ActionController::Parameters.new({ filter: { filternotexists: "John Smith" } })
      )
    end

    it "can filter with an invalid sort param" do
      FilterOnlyFilterableTestModel.filter(
        params: ActionController::Parameters.new({ sort: "invalidsortingkey" })
      )
    end
  end

  context "with only sort scope mappings" do
    it "can filter with no params" do
      SortOnlyFilterableTestModel.filter(
        params: ActionController::Parameters.new
      )
    end

    it "can filter with a valid sort param" do
      SortOnlyFilterableTestModel.filter(
        params: ActionController::Parameters.new({ sort: "name" })
      )
    end

    it "can filter with an invalid sort param" do
      SortOnlyFilterableTestModel.filter(
        params: ActionController::Parameters.new({ sort: "invalidsortingkey" })
      )
    end

    it "can filter with an invalid filter param" do
      SortOnlyFilterableTestModel.filter(
        params: ActionController::Parameters.new({ filter: { filternotexists: "John Smith" } })
      )
    end
  end

  context "with an explicitly declared reversed sort" do
    with_model :SortReversedFilterableTest, scope: :all do
      table do |t|
        t.string :name
        t.integer :favorite_number
      end

      model do
        include SnFilterable::Filterable

        SortReversedFilterableTest::SORT_SCOPE_MAPPINGS = { # rubocop:disable RSpec/LeakyConstantDeclaration
          "name": :sort_by_name
        }.freeze

        scope :sort_by_name, -> { order :name }
        scope :sort_by_name_reversed, -> { order :favorite_number }
      end
    end

    before do
      create_list(:sort_reversed_filterable_test, 10)
    end

    it "can sort" do
      expected_items = SortReversedFilterableTest.order("name ASC").map(&:name)

      filtered = SortReversedFilterableTest.filter(params: ActionController::Parameters.new({ sort: "name", order: "asc" }))

      expect(filtered.items.map(&:name)).to eq(expected_items)
    end

    it "can reverse sort" do
      expected_items = SortReversedFilterableTest.order("favorite_number ASC").map(&:favorite_number)

      filtered = SortReversedFilterableTest.filter(params: ActionController::Parameters.new({ sort: "name", order: "desc" }))

      expect(filtered.items.map(&:favorite_number)).to eq(expected_items)
    end
  end

  context "with a filter that supports arrays" do
    with_model :ArrayFilterFilterableTestModel, scope: :all do
      table do |t|
        t.string :name
        t.integer :favorite_number
      end

      model do
        include SnFilterable::Filterable

        ArrayFilterFilterableTestModel::FILTER_SCOPE_MAPPINGS = { # rubocop:disable RSpec/LeakyConstantDeclaration
          "name": :filter_by_name,
          "favorite_number": :filter_by_favorite_number
        }.freeze

        ArrayFilterFilterableTestModel::ARRAY_FILTER_SCOPES = [:favorite_number].freeze # rubocop:disable RSpec/LeakyConstantDeclaration

        scope :filter_by_name, ->(name) { where("name = ?", name) }
        scope :filter_by_favorite_number, ->(favorite_number) { where("favorite_number = ?", favorite_number) }
      end
    end

    before do
      create_list(:array_filter_filterable_test_model, 10)
    end

    let(:first_item) { ArrayFilterFilterableTestModel.first }
    let(:last_item) { ArrayFilterFilterableTestModel.last }

    it "can filter with a scope that takes an array" do # rubocop:disable RSpec/MultipleExpectations
      all_items = ArrayFilterFilterableTestModel.where(nil)
      expected_items = ArrayFilterFilterableTestModel.where("favorite_number = ? OR favorite_number = ?", first_item.favorite_number, last_item.favorite_number)

      filtered = ArrayFilterFilterableTestModel.filter(params: ActionController::Parameters.new({ filter: { favorite_number: [first_item.favorite_number, last_item.favorite_number] } }))

      expect(filtered.items).to match_array(expected_items)
      expect(filtered.items).not_to match_array(all_items)
    end

    it "can filter with a scopes that takes an array and with a non-array" do # rubocop:disable RSpec/MultipleExpectations
      all_items = ArrayFilterFilterableTestModel.where(nil)
      expected_items = ArrayFilterFilterableTestModel.where("name = ? AND (favorite_number = ? OR favorite_number = ?)", first_item.name, first_item.favorite_number, last_item.favorite_number)

      filtered = ArrayFilterFilterableTestModel.filter(params: ActionController::Parameters.new({ filter: { name: first_item.name, favorite_number: [first_item.favorite_number, last_item.favorite_number] } }))

      expect(filtered.items).to match_array(expected_items)
      expect(filtered.items).not_to match_array(all_items)
    end

    it "won't filter with scopes that don't support arrays" do
      all_items = ArrayFilterFilterableTestModel.where(nil)

      filtered = ArrayFilterFilterableTestModel.filter(params: ActionController::Parameters.new({ filter: { name: [first_item.name, last_item.name] } }))

      expect(filtered.items).to match_array(all_items)
    end
  end

  context "when creating a Filtered instance" do
    let(:empty_query_hash) { { "filter" => {} }.freeze }

    it "has the correct properties", :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new)

      expect(filtered.instance_variable_get(:@model_class)).to eq(BasicFilterableTestModel)
      expect(filtered.instance_variable_get(:@items)).to match_array(BasicFilterableTestModel.where(nil))
      expect(filtered.instance_variable_get(:@queries)).to eq(empty_query_hash)
      expect(filtered.instance_variable_get(:@sort_scope)).to eq(nil)
      expect(filtered.instance_variable_get(:@sort_reversed)).to eq(false)
      expect(filtered.instance_variable_get(:@extra_params)).to eq({})
    end
    
    it "correctly stores extra_params", :aggregate_failures do
      extra_params = { "tab" => "active", "view" => "list" }
      filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new, extra_params: extra_params)

      expect(filtered.instance_variable_get(:@extra_params)).to eq(extra_params)
    end

    context "with @queries" do
      it "removes invalid filters" do
        filtered = BasicFilterableTestModel.filter(
          params: ActionController::Parameters.new({ filter: { name: "test", thisisinvalid: "yes" } })
        )

        expect(filtered.instance_variable_get(:@queries)).to eq({ "filter" => { "name" => "test" } })
      end

      it "removes invalid sort" do
        filtered = BasicFilterableTestModel.filter(
          params: ActionController::Parameters.new({ sort: "invalidsortingscope" })
        )

        expect(filtered.instance_variable_get(:@queries)).to eq(empty_query_hash)
      end

      it "removes invalid sort with order" do
        filtered = BasicFilterableTestModel.filter(
          params: ActionController::Parameters.new({ sort: "invalidsortingscope", order: "desc" })
        )

        expect(filtered.instance_variable_get(:@queries)).to eq(empty_query_hash)
      end

      it "removes sort when order is invalid" do
        filtered = BasicFilterableTestModel.filter(
          params: ActionController::Parameters.new({ sort: "name", order: "invalidsortingorder" })
        )

        expect(filtered.instance_variable_get(:@queries)).to eq(empty_query_hash)
      end

      describe "pagination" do # rubocop:disable RSpec/NestedGroups
        it "retains valid pagination parameters" do
          filtered = BasicFilterableTestModel.filter(
            params: ActionController::Parameters.new({ page: "10", per: "50" })
          )

          expect(filtered.instance_variable_get(:@queries)).to include("page" => "10", "per" => "50")
        end

        it "removes pagination if per page is out of limits" do
          filtered = BasicFilterableTestModel.filter(
            params: ActionController::Parameters.new({ page: "1", per: "999999999999" })
          )

          expect(filtered.instance_variable_get(:@queries)).to eq(empty_query_hash)
        end
      end
    end

    context "with @sort_scope" do
      it "is nil when no default sort" do
        filtered = EmptyFilterableTestModel.filter(params: ActionController::Parameters.new)

        expect(filtered.instance_variable_get(:@sort_scope)).to eq(nil)
      end

      it "matches parameter's default sort" do
        expected_sort = "name"
        filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new, default_sort: expected_sort)

        expect(filtered.instance_variable_get(:@sort_name)).to eq(expected_sort)
      end
    end

    context "with @sort_reversed" do
      it "is false when no order specified" do
        expected_sort = "name"
        filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new, default_sort: expected_sort)

        expect(filtered.instance_variable_get(:@sort_reversed)).to eq(false)
      end

      it "is false when ascending order specified" do
        filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new, default_sort: ["name", :asc])

        expect(filtered.instance_variable_get(:@sort_reversed)).to eq(false)
      end

      it "is true when descending order specified" do
        filtered = BasicFilterableTestModel.filter(params: ActionController::Parameters.new, default_sort: ["name", :desc])

        expect(filtered.instance_variable_get(:@sort_reversed)).to eq(true)
      end
    end
  end
end

RSpec.describe SnFilterable::WhereHelper do
  describe ".contains" do
    subject { described_class.contains(column_key, value) }

    let(:column_key) { "some_column" }
    let(:value) { "SOme VALue" }

    it "returns a valid query" do
      expect(subject).to eq(["strpos(LOWER(#{column_key}), ?) > 0", value.downcase]) # rubocop:disable RSpec/NamedSubject
    end
  end
end

RSpec.describe SnFilterable::PolymorphicHelper, type: :model do
  describe ".joins" do
    subject { described_class.joins(relation, polymorphic_association, models) }

    let(:relation) { DummyModel.all } # Any model will work here
    let(:polymorphic_association) { "associationname" }
    let(:models) { [DummyModel] }

    it "creates a valid SQL query", :aggregate_failures do
      expect(subject.to_sql).to include(generate_join_sql(models[0])) # rubocop:disable RSpec/NamedSubject
    end

    def generate_join_sql(model)
      base_model_table = relation.table.name
      first_model_table = model.table_name
      first_model_name = model.name
      polymorphic_association_id = "#{polymorphic_association}_id"
      polymorphic_association_type = "#{polymorphic_association}_type"

      if ActiveRecord::Base.connection_db_config.adapter == "mysql2"
        "LEFT OUTER JOIN `#{first_model_table}` ON `#{first_model_table}`.id = `#{base_model_table}`.`#{polymorphic_association_id}` AND `#{base_model_table}`.`#{polymorphic_association_type}` = '#{first_model_name}'"
      else
        "LEFT OUTER JOIN \"#{first_model_table}\" ON \"#{first_model_table}\".id = \"#{base_model_table}\".\"#{polymorphic_association_id}\" AND \"#{base_model_table}\".\"#{polymorphic_association_type}\" = '#{first_model_name}'"
      end
    end
  end

  describe ".coalesce" do
    it "creates a valid function" do
      actual_output = described_class.coalesce([DummyModel], "some_column")

      if ActiveRecord::Base.connection_db_config.adapter == "mysql2"
        expect(actual_output).to eq("coalesce(`dummy_models`.`some_column`)")
      else
        expect(actual_output).to eq("coalesce(\"dummy_models\".\"some_column\")")
      end
    end
  end
end
