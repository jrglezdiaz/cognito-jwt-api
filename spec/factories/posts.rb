FactoryBot.define do
  factory :post do
    title { Faker::Lorem.sentence(word_count: 4) }
    content { Faker::Lorem.paragraph(sentence_count: 10) }
    user_id { Faker::Internet.uuid }
    published { false }

    trait :published do
      published { true }
    end

    trait :unpublished do
      published { false }
    end
  end
end
