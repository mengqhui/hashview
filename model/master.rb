require 'rubygems'
require 'data_mapper'
require 'bcrypt'

# debug cmd:
DataMapper::Logger.new($stdout, :debug)

# use for mysql
options = YAML.load_file('config/database.yml')
DataMapper.setup(:default, options['default'])

# use for sqlite db
# DataMapper.setup(:default, "sqlite://#{Dir.pwd}/db/master.db")

# User class object to handle user account credentials
class User
  include DataMapper::Resource

  property :id, Serial
  property :username, String, key: true, length: (3..40), required: true
  property :hashed_password, String, length: 128
  property :admin, Boolean
  property :created_at, DateTime, default: DateTime.now
  property :phone, String, required: false
  property :email, String, required: false

  attr_accessor :password
  validates_presence_of :username

  def password=(pass)
    @password = pass
    self.hashed_password = User.encrypt(@password)
  end

  def self.encrypt(pass)
    BCrypt::Password.create(pass)
  end

  def self.authenticate(username, pass)
    user = User.first(username: username)
    if user
      return user.username if BCrypt::Password.new(user.hashed_password) == pass
    end
  end
end

# Class to handle authenticated sessions
class Sessions
  include DataMapper::Resource

  property :id, Serial
  property :session_key, String, length: 128
  property :username, String, length: (3..40), required: true

  def self.isValid?(session_key)
    sessions = Sessions.first(session_key: session_key)

    return true if sessions
  end

  def self.type(session_key)
    sess = Sessions.first(session_key: session_key)

    if sess
      if User.first(username: sess.username).admin
        return TRUE
      else
        return FALSE
      end
    end
  end

  def self.getUsername(session_key)
    sess = Sessions.first(session_key: session_key)

    return sess.username if sess
  end
end

# Each Customer record will be stored here
class Customers
  include DataMapper::Resource
  property :id, Serial
  property :name, String, length: 40
  property :description, String, length: 500
end

# Each job generated by user will be stored here
class Jobs
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :last_updated_by, String, length: 40
  property :updated_at, DateTime, default: DateTime.now
  property :status, Boolean
  property :status_detail, String, length: 100
  property :targettype, String, length: 2000
  property :targetfile, String, length: 2000
  property :targethash, String, length: 2000
  property :policy_min_pass_length, Integer
  property :policy_complexity_default, Boolean
  property :customer_id, Integer
end

# Jobs will have multiple crack tasks
class Jobtasks
  include DataMapper::Resource

  property :id, Serial
  property :job_id, Integer
  property :task_id, Integer
  property :build_cmd, String, length: 5000
  # status options should be "Running", "Paused", "Not Started", "Completed", "Queued", "Failed", "Canceled"
  property :status, String
  property :run_time, Integer
end

# Task definitions
class Tasks
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :source, String
  property :mask, String
  property :command, String, length: 4000
  property :wl_id, String, length: 256
  property :hc_attackmode, Integer
  property :hc_rule, String
end

# Table for handle the storage of uncracked/cracked hashes per job
class Targets
  include DataMapper::Resource

  property :id, Serial
  property :username, String, length: 2000
  property :originalhash, String, length: 4000
  property :hashtype, Integer
  property :cracked, Boolean
  property :plaintext, String, length: 2000
  property :jobid, Integer
  property :customerid, Integer
end

# User Settings
class Settings
  include DataMapper::Resource

  property :id, Serial
  property :hcbinpath, String, length: 2000
  property :hcglobalopts, String, length: 2000
  property :maxtasktime, String, length: 2000
  property :maxjobtime, String, length: 2000
  property :clientmode, Boolean
end

 class Wordlists
   include DataMapper::Resource

   property :id, Serial
   property :name, String, length: 256
   property :path, String, length: 2000
   property :size, Integer

 end

DataMapper.finalize

# automatically update db based on model changes
DataMapper.auto_upgrade!
