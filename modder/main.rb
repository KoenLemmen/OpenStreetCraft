#!/usr/bin/env ruby

require 'json'

def find_ways(data, key, tag = nil)
  ways = data['way']
  if tag
    begin
      send("find_ways_#{key}", ways, tag)
    rescue NoMethodError
      data['way'].select do |elem|
        elem['tags'][key.to_s] == tag.to_s
      end
    end
  else
    ways.select do |elem|
      elem['tags'].keys.include? key
    end
  end
end

def find_node_refs(data, key, ways)
  ways.map do |w|
    w['nodeRefs'].map do |node_ref|
      begin
        send("get_node_#{key}", data, w, node_ref)
      rescue NoMethodError
        node(data, node_ref)
      end
    end
  end
end

def node(data, node_ref)
  node = data['node'][node_ref.to_s]
  [node['lat'].to_f, node['lon'].to_f]
end

def cubes_to_trace(key, list_nodes)
  begin
    send("process_#{key}", list_nodes)
  rescue NoMethodError
    raise "The function 'process_#{key}' must be defined"
  end
end

def create_mod(data, key, list_cubes, data_value)
  elevation = data['elevation'].each_slice(1000).to_a
  unless elevation.empty?
    begin
      send("draw_#{key}", elevation, list_cubes)
    rescue
      list_cubes.flatten(2).map do |c|
        (x, y) = c
        x = 0
        y = y|| 0
        [x, y, elevation[x][y], data_value]
      end
    end
  end
end

def process_main(map_data, osm_data, types)
  mods = types.map do |(key, values)|
    mod = values.map do |(type, data_value)|
      begin
        require "./mod_#{key}"
      rescue LoadError
        raise "Cannot found file ./mod_#{key}.rb"
      end

      ways = find_ways(osm_data, key, type)
      unless ways.empty?
        list_nodes = find_node_refs(osm_data, key, ways)
        list_cubes = cubes_to_trace(key, list_nodes)
        create_mod(map_data, key, list_cubes, data_value)
      end
    end

    mod.compact
  end

  require 'pry'; binding.pry
  map_data['mods'] = mods.reject { |c| c.empty? }.flatten
  map_data
end

map_file = '../data/map.json'
map_data = JSON.parse(File.open(map_file).read)
osm_data_file = '../data/OSMData.json'
osm_data = JSON.parse(File.open(osm_data_file).read)
types_file = '../data/types.json'
types = JSON.parse(File.open(types_file).read)

data = process_main(map_data, osm_data, types)
File.write(map_file, data.to_json)
require 'pry'; binding.pry