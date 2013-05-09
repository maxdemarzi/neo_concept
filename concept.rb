require 'set'
require 'bloomfilter-rb'

# Count the number of times we see the node to find the Dense nodes 
# in concept 5

def get_node_id(node)
  id = @node_hash[node]
  unless id
    @node_index += 1
    @node_hash[node] = @node_index
    @nodes.puts node
    @node_index
  end
  id || @node_index 
end

def is_unique_rel(from,to,rel)
  return false if @edge_bf.include?("#{from}-#{to}-#{rel}")
  @edge_bf.insert("#{from}-#{to}-#{rel}")
  true
end

def create_graph
  @node_index= 0
  @node_hash = {}
  @nodes = File.new("nodes.csv", "w")
  @edges = File.new("edges.csv", "w")

  # Label for CSV files
  @nodes.puts "id"
  @edges.puts "from\tto\trel\tcontext\tweight\treason"
  
  @edge_bf = BloomFilter::Native.new(:size => 212000000, :hashes => 23, :bucket => 8, :raise => false)        

  Dir.glob("csv_20130408/*.csv") { |file|
    puts "Processing " + file
    first = true
    File.open(file, "r").each_line do |line|
      if first
        first = false
        next
      end
      row = line.split("\t")

      from =  get_node_id(row[2]) #[6..-1]
      to = get_node_id(row[3])    #[6..-1]    
      rel = row[1][3..-1]
      
      if is_unique_rel(from, to, rel)
        context = row[4][5..-1]
        weight = row[5].strip + "L"
        reason = row[9].gsub('[[','"').gsub(']]','"')
        @edges.puts "#{from}\t#{to}\t#{rel}\t#{context}\t#{weight}\t#{reason}"
      end

    end  
      puts @edge_bf.stats      
  }
  create_nodes_index
end

def create_nodes_index
  puts "Generating Node Index..."
  nodes = File.open("nodes.csv", "r")
  nodes_index = File.open("nodes_index.csv","w")
  counter = 0
  
  while (line = nodes.gets)
    nodes_index.write("#{counter}\t#{line}")
    counter += 1
  end
  
  nodes.close
  nodes_index.close
end


def load_graph
  puts "Running the following:"
  command ="java -server -Xmx4G -jar ./../batch-import/target/batch-import-jar-with-dependencies.jar neo4j/data/graph.db nodes.csv edges.csv node_index Concepts exact nodes_index.csv" 
  puts command
  exec command    
end
