require 'neography/tasks'
require './concept'
  
namespace :neo4j do
  task :create do
    %x[rm *.csv]
    create_graph
  end

  task :load do
    %x[rm -rf neo4j/data/graph.db]
    load_graph
  end
end