ElasticSchema::Schema::Definition.new do
  index    :articles
  analysis :default

  type :article do
    field :title, :string, analyzer: :lowcase_word_delimiter
    field :content, :string, analyzer: :lowcase_word_delimiter
    field :author do
      field :name do
        field :first_name, :string
        field :last_name, :string
      end
      field :email, :string, index: :not_analyzed
    end
    field :indexed_at, :date, index: :not_analyzed
  end

  type :comment do
    field :article_id, :integer
    field :content, :string, analyzer: :lowcase_word_delimiter
    field :author do
      field :name do
        field :first_name, :string
        field :last_name, :string
      end
      field :email, :string, index: :not_analyzed
    end
    field :indexed_at, :date, index: :not_analyzed
  end
end
