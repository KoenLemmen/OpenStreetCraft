#!/usr/bin/env ruby

require 'json'

def highways(data, tag = nil)
  if tag
    data['way'].select do |elem|
      elem['tags']['highway'] == tag.to_s
    end
  else
    data['way'].select do |elem|
      elem['tags'].keys.include? 'highway'
    end
  end
end

def node_refs(data, ways)
  ways.map do |w|
    w['nodeRefs'].map do |nr|
      node(data, nr)
    end
  end
end

def node(data, node_ref)
  node = data['node'][node_ref.to_s]
  lat, lon = node['lat'], node['lon']
  OpenStruct.new({lat: lat, lon: lon})
end

def cubes_to_trace(list_nodes)
  list_nodes.map do |nodes|
    nodes.each_cons(2).map do |(node1, node2)|
      cubes_on_segment(node1, node2)
    end
  end
end

def slope(node1, node2)
  node2.lat - node1.lat / node2.lon - node1.lon
end

def cubes_on_segment(node1, node2)
  Range.new(node1.lon, node2.lon).map do |n|
    slope(node1, node2) * n
  end
end



json_file = './OSMData.json'
data = JSON.parse(File.open(json_file).read)

# all
highways = highways data
p highways.first
p highways.count

# with filter
primaries = highways data, :primary
p primaries.first
p primaries.count

# nodes
list_nodes = node_refs(data, highways)
p list_nodes.first
p list_nodes.count

# all cubes to trace
cubes = cubes_to_trace(list_nodes)
p cubes.first
p cubes.count
