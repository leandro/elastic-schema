# Elastic Schema

Elasticsearch schema manager for Ruby

# Description

A stateful way to approach Elasticsearch document mappings and data migrations.

The idea is to provide an easy and versionable way to register the mappings of your Elasticsearch indices and types.
Once any of the mappings and/or settings suffers any change by a developer, this tool kit will provide you means to keep your running elastic search server up-to-date regarding the recent changes.

The default strategy adopted by this tool is to create a new index with temporary name in order to create a whole new mapping that reflects the up-to-date mapping in the codebase. Once it's done it'll try (by default) to reindex all the data present in old index to the new one and once it's done it'll remove the old index and rename the new one.

## Install

    gem install elastic-schema

## Usage

Firstly, load the gem in your Gemfile:

    gem "elastic-schema", :git => "git://github.com/leandro/elastic-schema.git"

Then, run bundle install in your app root directory and just run:

    eschema -h 127.0.0.1:9201 -s directory/where/your/es/schemas/are/ create

For further information just run:

    eschema --help

## Contribute

If you want to contribute, please fork this project, make the changes and create a Pull Request mentioning me.
