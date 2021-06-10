# frozen_string_literal: true

#--
# Copyright (c) 2004-2021 David Heinemeier Hansson
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require "active_support"
require "active_support/rails"
require "active_model"
require "arel"
require "yaml"

require "active_record/version"
require "active_model/attribute_set"
require "active_record/errors"

module ActiveRecord
  extend ActiveSupport::Autoload

  autoload :Base
  autoload :Callbacks
  autoload :Core
  autoload :ConnectionHandling
  autoload :CounterCache
  autoload :DynamicMatchers
  autoload :DelegatedType
  autoload :Encryption
  autoload :Enum
  autoload :InternalMetadata
  autoload :Explain
  autoload :Inheritance
  autoload :Integration
  autoload :Migration
  autoload :Migrator, "active_record/migration"
  autoload :ModelSchema
  autoload :NestedAttributes
  autoload :NoTouching
  autoload :TouchLater
  autoload :Persistence
  autoload :QueryCache
  autoload :Querying
  autoload :ReadonlyAttributes
  autoload :RecordInvalid, "active_record/validations"
  autoload :Reflection
  autoload :RuntimeRegistry
  autoload :Sanitization
  autoload :Schema
  autoload :SchemaDumper
  autoload :SchemaMigration
  autoload :Scoping
  autoload :Serialization
  autoload :Store
  autoload :SignedId
  autoload :Suppressor
  autoload :Timestamp
  autoload :Transactions
  autoload :Translation
  autoload :Validations
  autoload :SecureToken
  autoload :DestroyAssociationAsyncJob

  eager_autoload do
    autoload :StatementCache
    autoload :ConnectionAdapters

    autoload :Aggregations
    autoload :Associations
    autoload :AttributeAssignment
    autoload :AttributeMethods
    autoload :AutosaveAssociation
    autoload :AsynchronousQueriesTracker

    autoload :LegacyYamlAdapter

    autoload :Relation
    autoload :AssociationRelation
    autoload :DisableJoinsAssociationRelation
    autoload :NullRelation

    autoload_under "relation" do
      autoload :QueryMethods
      autoload :FinderMethods
      autoload :Calculations
      autoload :PredicateBuilder
      autoload :SpawnMethods
      autoload :Batches
      autoload :Delegation
    end

    autoload :Result
    autoload :FutureResult
    autoload :TableMetadata
    autoload :Type
  end

  module Coders
    autoload :YAMLColumn, "active_record/coders/yaml_column"
    autoload :JSON, "active_record/coders/json"
  end

  module AttributeMethods
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :BeforeTypeCast
      autoload :Dirty
      autoload :PrimaryKey
      autoload :Query
      autoload :Read
      autoload :TimeZoneConversion
      autoload :Write
      autoload :Serialization
    end
  end

  module Locking
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Optimistic
      autoload :Pessimistic
    end
  end

  module Scoping
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Named
      autoload :Default
    end
  end

  module Middleware
    extend ActiveSupport::Autoload

    autoload :DatabaseSelector, "active_record/middleware/database_selector"
  end

  module Tasks
    extend ActiveSupport::Autoload

    autoload :DatabaseTasks
    autoload :SQLiteDatabaseTasks, "active_record/tasks/sqlite_database_tasks"
    autoload :MySQLDatabaseTasks,  "active_record/tasks/mysql_database_tasks"
    autoload :PostgreSQLDatabaseTasks,
      "active_record/tasks/postgresql_database_tasks"
  end

  autoload :TestDatabases, "active_record/test_databases"
  autoload :TestFixtures, "active_record/fixtures"

  singleton_class.attr_accessor :legacy_connection_handling
  self.legacy_connection_handling = true

  ##
  # :singleton-method:
  # Determines whether to use Time.utc (using :utc) or Time.local (using :local) when pulling
  # dates and times from the database. This is set to :utc by default.
  singleton_class.attr_accessor :default_timezone
  self.default_timezone = :utc

  singleton_class.attr_accessor :writing_role
  self.writing_role = :writing

  singleton_class.attr_accessor :reading_role
  self.reading_role = :reading

  ##
  # :singleton-method:
  # Specify a threshold for the size of query result sets. If the number of
  # records in the set exceeds the threshold, a warning is logged. This can
  # be used to identify queries which load thousands of records and
  # potentially cause memory bloat.
  singleton_class.attr_accessor :warn_on_records_fetched_greater_than
  self.warn_on_records_fetched_greater_than = false

  singleton_class.attr_accessor :application_record_class
  self.application_record_class = nil

  ##
  # :singleton-method:
  # Set the application to log or raise when an association violates strict loading.
  # Defaults to :raise.
  singleton_class.attr_accessor :action_on_strict_loading_violation
  self.action_on_strict_loading_violation = :raise

  ##
  # :singleton-method:
  # Specifies the format to use when dumping the database schema with Rails'
  # Rakefile. If :sql, the schema is dumped as (potentially database-
  # specific) SQL statements. If :ruby, the schema is dumped as an
  # ActiveRecord::Schema file which can be loaded into any database that
  # supports migrations. Use :ruby if you want to have different database
  # adapters for, e.g., your development and test environments.
  singleton_class.attr_accessor :schema_format
  self.schema_format = :ruby

  ##
  # :singleton-method:
  # Specifies if an error should be raised if the query has an order being
  # ignored when doing batch queries. Useful in applications where the
  # scope being ignored is error-worthy, rather than a warning.
  singleton_class.attr_accessor :error_on_ignored_order
  self.error_on_ignored_order = false

  ##
  # :singleton-method:
  # Specify whether or not to use timestamps for migration versions
  singleton_class.attr_accessor :timestamped_migrations
  self.timestamped_migrations = true

  ##
  # :singleton-method:
  # Specify whether schema dump should happen at the end of the
  # bin/rails db:migrate command. This is true by default, which is useful for the
  # development environment. This should ideally be false in the production
  # environment where dumping schema is rarely needed.
  singleton_class.attr_accessor :dump_schema_after_migration
  self.dump_schema_after_migration = true

  ##
  # :singleton-method:
  # Specifies which database schemas to dump when calling db:schema:dump.
  # If the value is :schema_search_path (the default), any schemas listed in
  # schema_search_path are dumped. Use :all to dump all schemas regardless
  # of schema_search_path, or a string of comma separated schemas for a
  # custom list.
  singleton_class.attr_accessor :dump_schemas
  self.dump_schemas = :schema_search_path

  ##
  # :singleton-method:
  # Show a warning when Rails couldn't parse your database.yml
  # for multiple databases.
  singleton_class.attr_accessor :suppress_multiple_database_warning
  self.suppress_multiple_database_warning = false

  def self.eager_load!
    super
    ActiveRecord::Locking.eager_load!
    ActiveRecord::Scoping.eager_load!
    ActiveRecord::Associations.eager_load!
    ActiveRecord::AttributeMethods.eager_load!
    ActiveRecord::ConnectionAdapters.eager_load!
    ActiveRecord::Encryption.eager_load!
  end
end

ActiveSupport.on_load(:active_record) do
  Arel::Table.engine = self
end

ActiveSupport.on_load(:i18n) do
  I18n.load_path << File.expand_path("active_record/locale/en.yml", __dir__)
end

YAML.load_tags["!ruby/object:ActiveRecord::AttributeSet"] = "ActiveModel::AttributeSet"
YAML.load_tags["!ruby/object:ActiveRecord::Attribute::FromDatabase"] = "ActiveModel::Attribute::FromDatabase"
YAML.load_tags["!ruby/object:ActiveRecord::LazyAttributeHash"] = "ActiveModel::LazyAttributeHash"
YAML.load_tags["!ruby/object:ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter::MysqlString"] = "ActiveRecord::Type::String"
