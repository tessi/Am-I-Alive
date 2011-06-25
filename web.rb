require 'sinatra'

get '/' do
  "please do:<br />\n<pre>\nheroku scale web=0 worker=1</pre>"
end