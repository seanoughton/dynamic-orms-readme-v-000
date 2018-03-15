require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song

  #this takes the class name, turns it into a lowercase string and pluralizes it
  def self.table_name
    self.to_s.downcase.pluralize
  end

#this gets a hash from the database of just the table names
#creates an empty array
#then shovels each column name into the array
#.compacts removes any nil elements in the array
#the return value is an array of column names
  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end
    column_names.compact
  end

#this iterates through the array of column names and assigns each name as an attr_accessor
#using the .to_sym to convert each name to a symbol
  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
  end

#this is the initialize statement for the class
#an empty hash is passed in as an optional argument
#each hash key(which is the name of one of the attr_accessor's, is assigned the value of the key)
  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

#this instance method returns the table name to be inserted with sequel
#this is here so that when an instance is created in memory, it can then be inserted into the db
#you need the table name in order to do that
  def table_name_for_insert
    self.class.table_name
  end

#this instance method returns the values to be inserted using sql
#it returns the string needed for the sql statement
#this is needed to add the instance to the database
#it creates an empty array for the values
#it iterates over the array of column names
#it takes the column name, which is also the attribute name
#and returns the value for that attribute
#it is equivalient to this values << :name (where this adds the value stored in the instance variable to the array)
  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

#this method returns a string for the sql statement
#the string has the column names necessary for the insert sql statement
#it removes the column names for id, because we won't be inserting the id
  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

#
  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end
