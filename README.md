## Description

A stateful way to approach Elasticsearch document mappings and data migrations.

The idea is to provide an easy and versionable way to register the mappings of your Elasticsearch indices and types.
Once any of the mappings and/or settings suffers any change by a developer, this tool kit will provide you means to keep your running elastic search server up-to-date regarding the recent changes.

The default strategy adopted by this tool is to create a new index with temporary name in order to create a whole new mapping that reflects the up-to-date mapping in the codebase. Once it's done it'll try (by default) to reindex all the data present in old index to the new one and once it's done it'll remove the old index and rename the new one.

## Usage

Go to your Ruby project where you Gemfile is located:

    $ cd ~/projects/my-ruby-project
    $ vim Gemfile

Add the following line to your Gemfile

    gem "elastic-schema", :git => "git://github.com/leandro/elastic-schema.git"

Choose a directory where you're going to put your Elasticsearch schemas. Or create one for yourself:

    $ mkdir -p db/es/

In order to see a working example, create the following file in the given your chosen directory:

    vim ./db/es/default.analysis.rb
-

    ElasticSchema::Schema::Analysis.new do
      name :default

      filter :word_filter, { type: :word_delimiter }
      analyzer :lowcase_word_delimiter, {
        type:      :custom,
        tokenizer: :standard,
        filter:    %i(lowercase asciifolding word_filter)
      }
    end

And also:

    vim ./db/es/articles.schema.rb
-

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

Then, run bundle install in your app root directory and run:

    $ eschema -h 127.0.0.1:9200 -s db/es/ create
    Initiating schema updates: 1 out of 1 will be updated.
    Creating index 'articles_v1436452769'
    Creating type 'article' in index 'articles_v1436452769'
    Creating type 'comment' in index 'articles_v1436452769'
    Creating alias 'articles' to index 'articles_v1436452769'

And lets say you have some documents inside the index later on:

    curl -XPUT http://127.0.0.1:9200/articles/article/1 -d '{"title": "Article A", "author": {"name": {"first_name": "Leandro", "last_name": "Camargo"}}, "indexed_at": "2015-07-08"}'
    curl -XPUT http://127.0.0.1:9200/articles/article/2 -d '{"title": "Article B", "author": {"name": {"first_name": "Leandro", "last_name": "Camargo"}}, "indexed_at": "2015-07-08"}'
    curl -XPUT http://127.0.0.1:9200/articles/article/3 -d '{"title": "Article C", "author": {"name": {"first_name": "Leandro", "last_name": "Camargo"}}, "indexed_at": "2015-07-08"}'
    curl -XPUT http://127.0.0.1:9200/articles/comment/1 -d '{"article_id": 1, "content": "First comment.", "author": {"name": {"first_name": "Leandro", "last_name": "Camargo"}}, "indexed_at": "2015-07-08"}'
    curl -XPUT http://127.0.0.1:9200/articles/comment/2 -d '{"article_id": 1, "content": "Second comment.", "author": {"name": {"first_name": "Leandro", "last_name": "Camargo"}}, "indexed_at": "2015-07-08"}'

Now, for instance, you change the analyzer for the 'content' field in your 'comment' type schema:

    # ...
    field :content, :string, analyzer: :snowball
    # ...

And then runs again the command. And you'll have this nice output:

    $ eschema -h 127.0.0.1:9200 -s db/es/ create
    Initiating schema updates: 1 out of 1 will be updated.
    Creating index 'articles_v1436453128'
    Creating type 'article' in index 'articles_v1436453128'
    Creating type 'comment' in index 'articles_v1436453128'
    Migrating 3 documents from type 'article' in index 'articles' to index 'articles_v1436453128'
    Migrating 2 documents from type 'comment' in index 'articles' to index 'articles_v1436453128'
    Creating alias 'articles' to index 'articles_v1436453128'
    Deleting index 'articles_v1436452769'

For further information just run:

    eschema --help

## Important observations

* All index schema you create, its file name must match the '*.schema.rb' pattern.
* The same goes for analysis settings, where it must match the '*.analysis.rb' or just naming it as 'analysis.rb' will also work.
* If you have indices with multiple types in it, make sure your index schema definition has **all the types definitions** in it, otherwise the missing types will be lost during the migration, given in most cases a new index will be created and the old one will be deleted.

## Contribute

If you want to contribute, please fork this project, make the changes and create a Pull Request mentioning me.
