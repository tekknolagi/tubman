require './app'

#h = Thin::Request::MAX_HEADER
#Thin::Request.send(:remove_const, :MAX_HEADER)
#Thin::Request::MAX_HEADER = h*100

run TubmanAPI
