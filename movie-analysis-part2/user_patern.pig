

-- Load movies.csv
movies = LOAD 'C:/Users/Alexandra/Desktop/movie-analysis-part2/movies.csv'
    USING PigStorage(',') 
    AS (movieId:chararray, title:chararray, genres:chararray);

-- Load ratings.csv
ratings = LOAD 'C:/Users/Alexandra/Desktop/movie-analysis-part2/ratings.csv'
    USING PigStorage(',') 
    AS (userId:chararray, movieId:chararray, rating:float, timestamp:chararray);

-- Split genres into individual genre entries. Make sure to ignore the movie title.
movies_expanded = FOREACH movies GENERATE 
    movieId, FLATTEN(TOKENIZE(genres, '\\|')) AS genre;

-- Join movies with ratings based on movieId
movies_ratings = JOIN ratings BY movieId, movies_expanded BY movieId;

-- Group data by userId and genre
user_genre_group = GROUP movies_ratings BY (ratings::userId, movies_expanded::genre);

-- Calculate average rating for each user-genre combination
user_genre_avg = FOREACH user_genre_group GENERATE 
    FLATTEN(group) AS (userId, genre), 
    AVG(movies_ratings.ratings::rating) AS avg_rating;

-- Filter out invalid genres (e.g., movie titles that are parsed as genres)
valid_genre_filter = FILTER user_genre_avg BY genre MATCHES '^[A-Za-z]+$';

-- Group by userId to prepare for finding max and min
user_group = GROUP valid_genre_filter BY userId;

-- Find highest and lowest rated genres for each user
user_preferences = FOREACH user_group {
    highest = TOP(1, 0, valid_genre_filter.(avg_rating, genre));
    lowest =  TOP(1, 1, valid_genre_filter.(avg_rating, genre));
    GENERATE group AS userId, highest, lowest;
};

-- Store the user preferences output
STORE user_preferences INTO 'C:/Users/Alexandra/Desktop/movie-analysis-part2/outputs/user_genre_preferences' 
    USING PigStorage(',');

-- Group data by genre
genre_group = GROUP movies_ratings BY movies_expanded::genre;

-- Calculate the average rating for each genre
genre_avg = FOREACH genre_group GENERATE 
    group AS genre, 
    AVG(movies_ratings.ratings::rating) AS avg_rating;

-- Filter out invalid genres
valid_genre_filter = FILTER genre_avg BY genre MATCHES '^[A-Za-z]+$';

-- Order genres by average rating in descending order
sorted_genres = ORDER valid_genre_filter BY avg_rating DESC;

STORE sorted_genres INTO 'C:/Users/Alexandra/Desktop/movie-analysis-part2/outputs/genre_rating' 
    USING PigStorage(',');