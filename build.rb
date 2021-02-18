#!/usr/bin/env ruby

require "open-uri"
require "json"
require "erb"
require "time"
require "fileutils"

template = File.open("index.html.erb", "rb", encoding: "utf-8", &:read)
css = File.open("main.css", "rb", encoding: "utf-8", &:read)

covid_deaths = JSON.parse(URI.open("https://covid.cdc.gov/covid-data-tracker/COVIDData/getAjaxData?id=statusBar_external_data").read)["statusBar"].first["us_total_deaths"]
as_of = Time.now.utc
cities = JSON.parse(File.read("cities.json"), symbolize_names: true)[:cities]

class Context < Struct.new(:template, :css, :covid_deaths, :as_of, :cities)
  MASS_SHOOTING_DEATHS = {
    "2019" => 465,
    "2018" => 371,
    "2017" => 437,
    "2016" => 451,
    "2015" => 368,
    "2014" => 262
  }

  EVENT_DEATHS = {
    "Spanish Flu" => 675_000,
    "Civil War" => 655_000,
    "WW2" => 405_399,
    "WW1" => 116_516,
    "Vietnam War" => 58_209,
    "Korean War" => 36_574,
    "2018-2019 Flu Season" => 34_200,
    "Revolutionary War" => 25_000,
    "Iraq War" => 4_576,
    "9/11" => 2_977,
    "2014-19 Mass Shootings" => MASS_SHOOTING_DEATHS.values.sum,
    "Afghanistan War" => 2_216
  }.sort_by{|_, deaths| -deaths }

  SOURCES = {
    "Wikipedia - US War Casualties" => "https://en.wikipedia.org/wiki/United_States_military_casualties_of_war#Wars_ranked_by_total_number_of_U.S._military_deaths",
    "Wikipedia - 9/11 Casualties" => "https://en.wikipedia.org/wiki/Casualties_of_the_September_11_attacks",
    "Wikipedia - List of US Cities by Population" => "https://en.wikipedia.org/wiki/List_of_United_States_cities_by_population",
    "CDC - 2018-2019 Flu Deaths" => "https://www.cdc.gov/flu/about/burden/2018-2019.html",
    "CDC - 1918 Pandemic" => "https://www.cdc.gov/flu/pandemic-resources/1918-pandemic-h1n1.html",
    "CDC COVID Data Tracker" => "https://covid.cdc.gov/covid-data-tracker/",
    "Gun Violence Archive" => "https://www.gunviolencearchive.org/",
  }

  def city_beneath(count=covid_deaths)
    cities.select{|c| c[:population] <= count }.sort_by{|c| c[:population] }.last
  end

  def city_above(count=covid_deaths)
    cities.select{|c| c[:population] >= count }.sort_by{|c| c[:population] }.first
  end

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

  def render
    @r ||= ERB.new(template).result(binding)
  end
end

FileUtils.mkdir_p("build")
FileUtils.cp("robots.txt", "build/robots.txt")
FileUtils.cp("deaths_graph.png", "build/deaths_graph.png")
File.write("build/index.html", Context.new(template, css, covid_deaths, as_of, cities).render)
