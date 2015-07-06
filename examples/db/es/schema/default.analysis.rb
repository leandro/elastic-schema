ElasticSchema::Schema::Analysis.new do
  name :default

  filter :trigrams_filter, {
    type:     :edgeNGram,
    min_gram: 3,
    max_gram: 20,
    side:     :front
  }
  filter :word_filter, { type: :word_delimiter }
  analyzer :lowcase_word_delimiter, {
    type:      :custom,
    tokenizer: :standard,
    filter:    %i(lowercase asciifolding word_filter)
  }
  analyzer :trigrams, {
    type:      :custom,
    tokenizer: :standard,
    filter:    %i(lowercase asciifolding trigrams_filter)
  }
end
