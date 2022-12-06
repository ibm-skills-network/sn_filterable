FactoryBot.define do
  factory :basic_filterable_test_model do
    name { Faker::Name.unique.name }
    favorite_number { Faker::Number.unique.between(from: 0, to: 100_000) }
  end

  factory :empty_filterable_test_model do
    name { Faker::Name.name }
  end

  factory :filter_only_filterable_test_model do
    name { Faker::Name.name }
  end

  factory :sort_only_filterable_test_model do
    name { Faker::Name.name }
  end

  factory :array_filter_filterable_test_model do
    name { Faker::Name.unique.name }
    favorite_number { Faker::Number.unique.between(from: 0, to: 100_000) }
  end

  factory :sort_with_explicit_reversed_filterable_test_model do
    name { Faker::Name.unique.name }
    favorite_number { Faker::Number.unique.between(from: 0, to: 100_000) }
  end
end
