--reading all the silver files
select * from silver_db.match_performance_silver;
select * from silver_db.match_stadium_silver;
select * from silver_db.player_performance_silver;
select * from silver_db.player_team_silver;
select * from silver_db.stadium_silver;
select * from silver_db.team_silver;

create schema gold_db;

--team summary gold table 
select
    t.team_name,
    count(mp.match_id) as total_matches,
    sum(case when mp.match_result = 'Win' then 1 else 0 end) as total_wins,
    round(sum(case when mp.match_result = 'Win' then 1 else 0 end) * 100 / count(mp.match_id), 0) as win_percentage,
    t.home_ground
into gold_db.ipl_team_performance_summary
from silver_db.match_performance_silver mp
join silver_db.team_silver t on mp.team_id=t.team_id
group by t.team_name, t.home_ground;


select * from gold_db.ipl_team_performance_summary

-- venue analysis gold table 
;with match_details as (
    select
        t.team_name,
        mp.match_id,
        mp.match_result,
        case 
            when t.home_ground=s.stadium_name then 'Home'
            else 'Away'
        end as match_location
    from silver_db.match_performance_silver mp
    join silver_db.match_stadium_silver ms on mp.match_id=ms.match_id
    join silver_db.stadium_silver s on ms.stadium_id=s.stadium_id
    join silver_db.team_silver t on mp.team_id=t.team_id
)

select
    team_name,
    match_location,
    count(match_id) as total_matches,
    sum(case when match_result = 'Win' then 1 else 0 end) as total_wins,
    count(match_id) - sum(case when match_result = 'Win' then 1 else 0 end) as total_losses,
    round(sum(case when match_result='Win' then 1 else 0 end) * 100.0 / count(match_id), 2) as win_percentage
into gold_db.venue_performance_summary 
from match_details
group by team_name,match_location;


select * from gold_db.venue_performance_summary

--team_player_performance_summary
select 
    pt.team_id,
    t.team_name,
    pp.player_id,
    pt.player_name,
    pt.player_role,
    count(distinct pp.match_id) as matches_played,
    sum(pp.runs_scored) as total_runs,
    sum(pp.wickets_taken) as total_wickets
into gold_db.team_player_performance_summary
from silver_db.player_performance_silver pp
join silver_db.player_team_silver pt on pp.player_id=pt.player_id
join silver_db.team_silver t on pt.team_id=t.team_id
group by pt.team_id,t.team_name,pp.player_id,pt.player_name,pt.player_role;

select *from gold_db.team_player_performance_summary

--player_efficiency_summary

select 
    pt.player_id,
    pt.player_name,
    pt.player_role,
    avg(case 
        when pp.ball_taken>0 then (pp.runs_scored *100.0 / nullif(pp.ball_taken,0)) 
        else NULL 
    end) as avg_strike_rate,
    sum(pp.runs_scored) as total_batting_runs,
    sum(pp.ball_taken) as total_balls_faced,
    count(distinct pp.match_id) as innings_played,
    round(sum(pp.runs_scored * 1.0)/nullif(count(distinct pp.match_id),0),2) as avg_runs_per_innings,
    sum(pp.wickets_taken) as total_wickets
into gold_db.player_efficiency_summary
from silver_db.player_performance_silver pp
join silver_db.player_team_silver pt on pp.player_id=pt.player_id
group by pt.player_id,pt.player_name, pt.player_role;


select * from gold_db.player_efficiency_summary


--player_match_venue_performance

select
    pp.player_id,
    pt.player_name,
    pt.player_role,
    pt.team_id,
    t.team_name,
    pp.match_id,
    ms.stadium_id,
    s.stadium_name,
    case 
        when t.home_ground = s.stadium_name then 1 else 0 
    end as is_home_match,
    pp.runs_scored,
    pp.wickets_taken,
    pp.ball_taken
into gold_db.player_match_venue_performance
from silver_db.player_performance_silver pp
join silver_db.player_team_silver pt on pp.player_id=pt.player_id
join silver_db.team_silver t on pt.team_id=t.team_id
join silver_db.match_stadium_silver ms on pp.match_id=ms.match_id
join silver_db.stadium_silver s on ms.stadium_id=s.stadium_id;

select * from gold_db.player_match_venue_performance
