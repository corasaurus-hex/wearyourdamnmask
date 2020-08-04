#!/usr/bin/env ruby

require "open-uri"
require "json"
require "erb"
require "time"
require "fileutils"

template = File.open("index.erb", "rb", encoding: "utf-8", &:read)
css = File.open("main.css", "rb", encoding: "utf-8", &:read)

covid_deaths = JSON.parse(URI.open("https://covidtracking.com/api/v1/us/current.json").read)[0]["death"]

class Context < Struct.new(:template, :css, :covid_deaths)
  EVENT_DEATHS = {
    "WW2" => 405_399,
    "WW1" => 116_516,
    "Vietnam War" => 58_209,
    "Korean War" => 36_574,
    "2018-2019 Flu Season" => 34_200,
    "Revolutionary War" => 25_000,
    "Iraq War" => 4_576,
    "9/11" => 2_977,
    "Afghanistan War" => 2_216
  }

  SOURCES = {
    "Wikipedia - US War Casualties" => "https://en.wikipedia.org/wiki/United_States_military_casualties_of_war#Wars_ranked_by_total_number_of_U.S._military_deaths",
    "Wikipedia - 9/11 Casualties" => "https://en.wikipedia.org/wiki/Casualties_of_the_September_11_attacks",
    "CDC - 2018-2019 Flu Deaths" => "https://www.cdc.gov/flu/about/burden/2018-2019.html",
    "The COVID Tracking Project" => "https://covidtracking.com/",
  }

  def number_with_delimiter(number)
    integral, fractional = number.to_s.split(".")

    integral.gsub!(/(\d)(?=(\d\d\d)+(?!\d))/) do |n|
      "#{n},"
    end

    [integral,fractional].compact.join(".")
  end

  def event_death_stats
    @wdaam ||= begin
                 EVENT_DEATHS.map{|event, deaths|
                   [event, {deaths: deaths, multiplier: "%0.2f" % (covid_deaths.to_f / deaths)}]
                 }.to_h
               end
  end

  def sources
    SOURCES
  end

  def as_of
    Time.now.utc.rfc822.gsub("-0000", "UTC")
  end

  def render
    @r ||= ERB.new(template).result(binding)
  end
end

FileUtils.mkdir_p("build")
File.write("build/index.html", Context.new(template, css, covid_deaths).render)
