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

  #n = 6.3M
  #p = 1/10M
  #m = 211,350,538
  #k = 23
  
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


module Memory
  # sizes are guessed, I was too lazy to look
  # them up and then they are also platform
  # dependent
  REF_SIZE = 4 # ?
  OBJ_OVERHEAD = 4 # ?
  FIXNUM_SIZE = 4 # ?

  # informational output from analysis
  MemoryInfo = Struct.new :roots, :objects, :bytes, :loops

  def self.analyze(*roots)
    an = Analyzer.new
    an.roots = roots
    an.analyze
  end

  class Analyzer
    attr_accessor :roots
    attr_reader   :result

    def analyze
      @result = MemoryInfo.new roots, 0, 0, 0
      @objs = {}

      queue = roots.dup

      until queue.empty?
        obj = queue.shift

        case obj
        # special treatment for some types
        # some are certainly missing from this
        when IO
          visit(obj)
        when String
          visit(obj) { @result.bytes += obj.size }
        when Fixnum
          @result.bytes += FIXNUM_SIZE
        when Array
          visit(obj) do
            @result.bytes += obj.size * REF_SIZE
            queue.concat(obj)
          end
        when Hash
          visit(obj) do
            @result.bytes += obj.size * REF_SIZE * 2
            obj.each {|k,v| queue.push(k).push(v)}
          end
        when Enumerable
          visit(obj) do
            obj.each do |o|
              @result.bytes += REF_SIZE
              queue.push(o)
            end
          end
        else
          visit(obj) do
            obj.instance_variables.each do |var|
              @result.bytes += REF_SIZE
              queue.push(obj.instance_variable_get(var))
            end
          end
        end
      end

      @result
    end

  private
    def visit(obj)
      id = obj.object_id

      if @objs.has_key? id
        @result.loops += 1
        false
      else
        @objs[id] = true
        @result.bytes += OBJ_OVERHEAD
        @result.objects += 1
        yield obj if block_given?
        true
      end
    end
  end
end
