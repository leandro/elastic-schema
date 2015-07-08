ElasticSchema::Schema::Analysis.new do
  name :default

  filter :word_filter, { type: :word_delimiter }
  analyzer :lowcase_word_delimiter, {
    type:      :custom,
    tokenizer: :standard,
    filter:    %i(lowercase asciifolding word_filter)
  }
end
