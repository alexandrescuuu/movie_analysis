-- Load the data files
movies = LOAD 'C:/Users/Alexandra/Desktop/movie_analysis/movies.csv' USING PigStorage(',') 
    AS (movie_id:chararray, title:chararray, genres:chararray);

ratings = LOAD 'C:/Users/Alexandra/Desktop/movie_analysis/ratings.csv' USING PigStorage(',') 
    AS (user_id:chararray, movie_id:chararray, rating:float, timestamp:chararray);

tags = LOAD 'C:/Users/Alexandra/Desktop/movie_analysis/tags.csv' USING PigStorage(',') 
    AS (user_id:chararray, movie_id:chararray, tag:chararray, timestamp:chararray);

-- Clean and prepare data (skip the header row if present)
movies_clean = FILTER movies BY movie_id != 'movieId';
ratings_clean = FILTER ratings BY movie_id != 'movieId';
tags_clean = FILTER tags BY movie_id != 'movieId';

-- Define the target movie ID (replace '1' with the actual movie ID you want to analyze)
--target_movie_id = '1';

-- Filter data for the target movie
target_movie = FILTER movies_clean BY movie_id == '10';

-- Get all ratings for the target movie
target_movie_ratings = FILTER ratings_clean BY movie_id == '10';

-- Get all tags for the target movie
target_movie_tags = FILTER tags_clean BY movie_id == '10';

-- Aggregate ratings data for the target movie
ratings_stats = FOREACH (GROUP target_movie_ratings ALL) GENERATE
    COUNT(target_movie_ratings) AS total_ratings,
    AVG(target_movie_ratings.rating) AS avg_rating,
    MIN(target_movie_ratings.rating) AS min_rating,
    MAX(target_movie_ratings.rating) AS max_rating;

-- Aggregate tag data for the target movie
tags_grouped = GROUP target_movie_tags BY tag;
tags_count = FOREACH tags_grouped GENERATE group AS tag, COUNT(target_movie_tags) AS tag_count;
tags_sorted = ORDER tags_count BY tag_count DESC;

-- Combine and display all data
target_movie_full_data = FOREACH (CROSS target_movie, ratings_stats) GENERATE
    target_movie::movie_id AS movie_id,
    target_movie::title AS title,
    target_movie::genres AS genres,
    ratings_stats::total_ratings AS total_ratings,
    ratings_stats::avg_rating AS avg_rating,
    ratings_stats::min_rating AS min_rating,
    ratings_stats::max_rating AS max_rating;

-- Dump all relevant data for the target movie
DUMP target_movie_full_data; -- Summary of movie details and ratings
DUMP target_movie_ratings; -- Individual ratings data for the target movie
DUMP tags_sorted; -- Tags associated with the target movie

-- Optional: Store results to output directories
STORE target_movie_full_data INTO 'C:/Users/Alexandra/Desktop/movie_analysis/output_for_a_movie/target_movie_summary' USING PigStorage(',');
STORE target_movie_ratings INTO 'C:/Users/Alexandra/Desktop/movie_analysis/output_for_a_movie/target_movie_ratings' USING PigStorage(',');
STORE tags_sorted INTO 'C:/Users/Alexandra/Desktop/movie_analysis/output_for_a_movie/target_movie_tags' USING PigStorage(',');
