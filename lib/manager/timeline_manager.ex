defmodule Etoile.TimelineManager do

  alias Etoile.Models.Timeline
  alias Etoile.RequestManager
  alias Etoile.HistoryManager
  alias Etoile.CalendarUtil
  alias Etoile.Parser

  def create( username ) do
    {year, _month, _day, week} = CalendarUtil.get_current_date()
    timeline = %Timeline{ username: username, year: year, week: week, status: "ACTIVE" }
    res = validate_timeline( timeline )
    case res do
      [] ->
        RequestManager.post("/timelines.json", timeline)
      timeline ->
		    Parser.print_with_color " [ This timeline is in use. ]", :color228
    end
  end

  def validate_timeline( timeline_to_save ) do
    RequestManager.get("/timelines.json")
      |> Enum.filter(
        fn {_id, timeline} ->
          timeline["username"] == timeline_to_save.username
          and timeline["week"] == timeline_to_save.week
          and timeline["year"] == timeline_to_save.year end )
  end

  def find_active_timeline( username ) do
    RequestManager.get("/timelines.json")
    |> Enum.filter(
      fn {_id, timeline} ->
        timeline["username"] == username
        and timeline["status"] == "ACTIVE" end )
  end

  def print_active_timeline( username ) do
    res =
      RequestManager.get("/timelines.json")
        |> Enum.filter(
          fn {_id, timeline} ->
            timeline["username"] == username
            and timeline["status"] == "ACTIVE" end )
    case res do
      nil ->
		    Parser.print_with_color " [ Add Timeline for start to use it ]", :color228
      [] ->
		    Parser.print_with_color " [ Add Timeline for start to use it ]", :color228
      [{_id, active}] ->
        CalendarUtil.print_current_week( active["year"], active["week"] )
    end
  end

  def display_all_from_user( username ) do
    timelines = get_all_from_user( username )
    case timelines do
      :empty ->
        Parser.print_with_color "[ Add a timeline for start to use it. ]", :color228
      timelines ->
        Enum.each( timelines, fn {_id, timeline} ->
          Parser.print_with_color " - Timeline Week #{timeline["week"]} Year #{timeline["year"]}", :color229
        end)
    end
  end

  def get_all_from_user( username ) do
    res =
      RequestManager.get("/timelines.json")
        |> Enum.filter( fn {_id, timeline} -> timeline["username"] == username end )
    case res do
      nil -> :empty
      [] -> :empty
      timelines -> timelines |> Enum.sort_by( fn {_id, timeline} -> timeline["week"]  end)
    end
  end

  def validate_current_timeline( username ) do
    {current_year, _month, _day, current_week} = CalendarUtil.get_current_date()
    [{id_in_api, active_timeline}] = find_active_timeline( username )
    week_validation = { current_week, current_year } == { active_timeline["week"], active_timeline["year"]}
    case week_validation do
      true ->
        CalendarUtil.print_current_week( active_timeline["year"], active_timeline["week"] )
      false ->
        active_timeline = Map.put( active_timeline, "status", "INACTIVE" )
        RequestManager.put( "/timelines/#{id_in_api}.json", active_timeline)
        create( username )
        validate_current_timeline( username )
        Parser.print_with_color " [ New Timeline Added ] ", :color229
    end
  end

  def show_timeline(week, year, username) do
    week = String.to_integer( week )
    year = String.to_integer( year )
    timelines = get_all_from_user( username )
    case timelines do
      :empty ->
        Parser.print_with_color "[ Timelines not found... ]", :color229
      timelines ->
        find_timeline_in_user_history( timelines, week, year )
        |> show_timeline_record( username )
    end
  end


  def find_timeline_in_user_history( timelines, week, year ) do
    Enum.filter( timelines, fn { _id, timeline} -> timeline["week"] == 52 and timeline["year"] == 2018 end)
  end

  def show_timeline_record( timeline, username ) do
    case timeline do
      [] -> Parser.print_with_color "[ Timeline not found. ]", :color228
      [{_id, timeline}] ->
        HistoryManager.display_timeline_history( timeline["week"], timeline["year"], username )
    end
  end

end
