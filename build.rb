#!/usr/bin/env ruby

require "open-uri"
require "json"
require "erb"
require "time"

template = File.open("index.erb", "rb", encoding: "utf-8", &:read)
css = File.open("main.css", "rb", encoding: "utf-8", &:read)

covid_deaths = JSON.parse(URI.open("https://covidtracking.com/api/v1/us/current.json").read)[0]["death"]

class Context < Struct.new(:template, :css, :covid_deaths)
  WAR_DEATHS = {
    "WW2" => 405_399,
    "WW1" => 116_516,
    "Vietnam War" => 58_209,
    "Korean War" => 36_574,
    "Revolutionary War" => 25_000,
    "Iraq War" => 4_576,
    "Afghanistan War" => 2_216
  }

  def number_with_delimiter(number)
    integral, fractional = number.to_s.split(".")

    integral.gsub!(/(\d)(?=(\d\d\d)+(?!\d))/) do |n|
      "#{n},"
    end

    [integral,fractional].compact.join(".")
  end

  def war_death_stats
    @wdaam ||= begin
                 WAR_DEATHS.map{|war, deaths|
                   [war, {deaths: deaths, multiplier: "%0.2f" % (covid_deaths.to_f / deaths)}]
                 }.to_h
               end
  end

  def as_of
    Time.now.utc.rfc822.gsub("-0000", "UTC")
  end

  def render
    @r ||= ERB.new(template).result(binding)
  end
end

File.write("build/index.html", Context.new(template, css, covid_deaths).render)
