require 'grape'
require 'data_mapper'
require 'dm-postgres-adapter'

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, ENV['HEROKU_POSTGRESQL_BLACK_URL'])

class TubmanAPI < Grape::API
  version :v1
  format :json

  get :/ do
    { :hello => :world }
  end
end
