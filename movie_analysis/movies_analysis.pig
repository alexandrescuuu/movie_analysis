-- Load the data files  
--C:\Users\Alexandra\Desktop\movie_analysis
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

-- Analysis 1: Top-Rated Movies
grouped_ratings = GROUP ratings_clean BY movie_id;
avg_ratings = FOREACH grouped_ratings GENERATE group AS movie_id, AVG(ratings_clean.rating) AS avg_rating;
top_rated_movies = ORDER avg_ratings BY avg_rating DESC;

-- Join with movies to get titles of top-rated movies
top_movies_with_titles = JOIN top_rated_movies BY movie_id, movies_clean BY movie_id;
top_movies_final = FOREACH top_movies_with_titles GENERATE movies_clean::title AS title, top_rated_movies::avg_rating AS avg_rating;
top_movies_final = Order top_movies_final By avg_rating DESC;

-- Store the result
STORE top_movies_final INTO 'C:/Users/Alexandra/Desktop/movie_analysis/output/top_rated_movies' USING PigStorage(',');

-- Analysis 2: Ratings Distribution
ratings_distribution = FOREACH grouped_ratings GENERATE group AS movie_id, COUNT(ratings_clean.rating) AS rating_count;
STORE ratings_distribution INTO 'C:/Users/Alexandra/Desktop/movie_analysis/output/ratings_distribution' USING PigStorage(',');

-- Analysis 3: Movies with the Most Ratings
most_rated_movies = ORDER ratings_distribution BY rating_count DESC;
STORE most_rated_movies INTO 'C:/Users/Alexandra/Desktop/movie_analysis/output/most_rated_movies' USING PigStorage(',');

-- -- Analysis 4: Average Rating per Genre
-- genres_split = FOREACH movies_clean GENERATE movie_id, FLATTEN(TOKENIZE(genres, '|')) AS genre;
-- movies_with_ratings = JOIN ratings_clean BY movie_id, genres_split BY movie_id;
-- grouped_by_genre = GROUP movies_with_ratings BY genres_split::genre;
-- avg_rating_by_genre = FOREACH grouped_by_genre GENERATE group AS genre, AVG(movies_with_ratings.rating) AS avg_rating;
-- avg_rating_by_genre_sorted = ORDER avg_rating_by_genre BY avg_rating DESC;
-- STORE avg_rating_by_genre_sorted INTO 'C:/Users/Alexandra/Desktop/movie_analysis/output/avg_rating_per_genre' USING PigStorage(',');

-- Analysis 5: Most Active Users
grouped_users = GROUP ratings_clean BY user_id;
user_ratings_count = FOREACH grouped_users GENERATE group AS user_id, COUNT(ratings_clean.rating) AS ratings_count;
active_users = ORDER user_ratings_count BY ratings_count DESC;
STORE active_users INTO 'C:/Users/Alexandra/Desktop/movie_analysis/output/most_active_users' USING PigStorage(',');

-- Analysis 6: Tag Cloud for Highly Rated Movies
highly_rated_movies = FILTER top_rated_movies BY avg_rating >= 4.0;
highly_rated_movie_ids = FOREACH highly_rated_movies GENERATE movie_id;
highly_rated_tags = JOIN tags_clean BY movie_id, highly_rated_movie_ids BY movie_id;
tags_grouped = GROUP highly_rated_tags BY tag;
tag_counts = FOREACH tags_grouped GENERATE group AS tag, COUNT(highly_rated_tags) AS tag_count;
top_tags = ORDER tag_counts BY tag_count DESC;
STORE top_tags INTO 'C:/Users/Alexandra/Desktop/movie_analysis/output/tag_cloud_high_rated_movies' USING PigStorage(',');

-- -- Analysis 7: Rating Trends Over Time
-- ratings_with_year = FOREACH ratings_clean GENERATE 
--     movie_id, 
--     rating, 
--     ToString(TIMESTAMP(timestamp)) AS date;
-- ratings_with_year_grouped = GROUP ratings_with_year BY (SUBSTRING(ratings_with_year.date, 0, 4)); -- Extract year
-- avg_rating_by_year = FOREACH ratings_with_year_grouped GENERATE group AS year, AVG(ratings_with_year.rating) AS avg_rating;
-- avg_rating_by_year_sorted = ORDER avg_rating_by_year BY year;
-- STORE avg_rating_by_year_sorted INTO '/home/hdoop/movie_analysis/output/rating_trends_over_time' USING PigStorage(',');
