require 'grape'
require 'data_mapper'
require 'dm-postgres-adapter'
require 'json'
require 'awesome_print'

#DataMapper::Logger.new($stdout, :debug)
#DataMapper.setup(:default, ENV['TUBMAN_DB_URL'])
DataMapper.setup(:default, 'postgres://max@localhost/test')

class PubKey
  include DataMapper::Resource

  property :id, Serial
  property :pubkey, Text, :length => 500000
end

class User
  include DataMapper::Resource

  property :id, Serial
  property :username, String
  property :password, BCryptHash

  has 1, :pub_key
  belongs_to :tub, :required => false
end

class Tub
  include DataMapper::Resource

  property :id, Serial
  property :image, Text, :length => 50000000

  has 1, :sender, User
  has 1, :receiver, User
end

DataMapper.finalize
DataMapper.auto_upgrade!

class TubmanAPI < Grape::API
  version :v1
  format :json

  helpers do
    SUCCESS_TRUE = { :success => true }
    SUCCESS_FALSE = { :success => false }
  end

  params do
    requires :username, :type => String
    requires :password, :type => String
    requires :pubkey, :type => String
  end
  post(:register) do
    u = User.first(:username => params[:username])
    if u
      SUCCESS_FALSE
    else
      k = PubKey.create(:pubkey => params[:pubkey])
      u = User.create(:username => params[:username], :password => params[:password], :pub_key => k)
      SUCCESS_TRUE
    end
  end

  params do
    requires :username, :type => String
    requires :password, :type => String
    requires :receiver, :type => String
    requires :file
  end
  post(:send) do
#    ap params
    u = User.first(:username => params[:username])
    nu = User.first(:username => params[:receiver])
    tf = params[:file][:tempfile]
#    tf.binmode
    f = tf.read()
    ap f[-10..-1]
    if u && (u.password == params[:password]) && nu
      t = Tub.create(:sender => u, :receiver => nu, :image => f)
      ap t.errors
      SUCCESS_TRUE
    else
      SUCCESS_FALSE
    end
  end

  params do
    requires :target, :type => String # key to fetch
  end
  post(:getkey) do
    u = User.first(:username => params[:target])
    if u
      SUCCESS_TRUE.merge(:response => u.pub_key.pubkey)
    else
      SUCCESS_FALSE
    end
  end

  params do
    requires :username, :type => String
    requires :password, :type => String
  end
  post(:receive) do
    u = User.first(:username => params[:username])
    if u && (u.password == params[:password])
      tubs = Tub.all(:receiver => u)
      tubs = tubs.map do |t|
                   ap t.image
                   t.attributes.merge(:image => t.image)
                 end
      ap tubs
      SUCCESS_TRUE.merge(:response => tubs.to_a)
    else
      SUCCESS_FALSE
    end
  end
end
