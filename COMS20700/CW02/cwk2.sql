-- CHANGE SCHEMA
ALTER SESSION SET current_schema = SHARED;

-- q1  What year was the film “Fight Club” made?
SELECT yr FROM movie WHERE title = 'Fight Club';

-- q2 What is the score of the film “Vertigo”? 
SELECT score FROM movie WHERE title = 'Vertigo';

-- q3  Who starred in the film “12 Angry Men”? 
SELECT name
FROM actor
INNER JOIN casting ON actor.id = casting.actorid
INNER JOIN movie ON casting.movieid = movie.id
WHERE title = '12 Angry Men'
  AND ord = 1;

-- q4 List the title and scores (in descending order) for the films directed by Joel Coen
SELECT title,
       score
FROM movie
INNER JOIN actor ON movie.director = actor.id
WHERE name = 'Joel Coen'
ORDER BY score DESC;

-- q5  List the titles of other films starring actors who appeared in the film “Alien”
SELECT m1.title
FROM movie m1
INNER JOIN casting c1 ON m1.id = c1.movieid
INNER JOIN casting c2 ON c1.actorid = c2.actorid
INNER JOIN movie m2 ON c2.movieid = m2.id
WHERE m1.title <> 'Alien'
  AND m2.title = 'Alien';

-- q6 Give the title and score of the best film of the final year of the database
SELECT *
FROM
  (SELECT title,
          score
   FROM movie
   ORDER BY yr DESC, score DESC) t
WHERE ROWNUM = 1;

-- q7 Give the title of the film with “John” in the title, which had actor(s) with first name “John”
SELECT DISTINCT title
FROM movie
INNER JOIN casting ON movie.id = casting.movieid
INNER JOIN actor ON casting.actorid = actor.id
WHERE title LIKE '%John%'
  AND name LIKE 'John %';

-- q8 List title, year and score for the films starring Kurt Russell and directed by John Carpenter
SELECT title,
       yr,
       score
FROM movie
INNER JOIN casting ON movie.id = casting.movieid
INNER JOIN actor a1 ON casting.actorid = a1.id
INNER JOIN actor a2 ON movie.director = a2.id
WHERE a1.name = 'Kurt Russell'
  AND ord = 1
  AND a2.name = 'John Carpenter';
  
-- q9  List the title, year and score for the best five films that Humphrey Bogart starred in
SELECT *
FROM
  (SELECT title,
          yr,
          score
   FROM movie
   INNER JOIN casting ON movie.id = casting.movieid
   INNER JOIN actor ON casting.actorid = actor.id
   WHERE name = 'Humphrey Bogart'
     AND ord = 1
   ORDER BY score DESC) t
WHERE ROWNUM <= 5;

-- q10 What’s the film that starred Jack Nicholson and its director also directed a film starring Johnny Depp?
SELECT m1.title
FROM movie m1
INNER JOIN casting c1 ON m1.id = c1.movieid
INNER JOIN actor a1 ON c1.actorid = a1.id
INNER JOIN actor a2 ON m1.director = a2.id
INNER JOIN movie m2 ON m2.director = m1.director
INNER JOIN casting c2 ON c2.movieid = m2.id
INNER JOIN actor a3 ON a3.id = c2.actorid
WHERE a1.name = 'Jack Nicholson'
  AND c1.ord = 1
  AND c2.ord = 1
  AND a3.name = 'Johnny Depp';

-- q11 List the actors in “The Godfather”, who weren’t in “The Godfather: Part II”
SELECT name
FROM actor
INNER JOIN casting ON actor.id = casting.actorid
INNER JOIN movie ON casting.movieid = movie.id
WHERE title = 'Godfather, The' 
  MINUS
SELECT name
FROM actor
INNER JOIN casting ON actor.id = casting.actorid
INNER JOIN movie ON casting.movieid = movie.id 
WHERE title = 'Godfather: Part II, The';

-- q12 List the title and score of the best and worst films in which Dennis Hopper appeared
-- We can't reference the renamed columns in the inner where clause, so we have to do an outer select
SELECT title
FROM
  (SELECT title,
          row_number() over (ORDER BY score DESC) AS rank,
          COUNT(*) OVER () AS endrank
   FROM movie
   INNER JOIN casting ON movie.id = casting.movieid
   INNER JOIN actor ON casting.actorid = actor.id
   WHERE name = 'Dennis Hopper')
WHERE rank = 1
  OR rank = endrank;

-- q13 In which year did Bruce Willis make most films (show the year and number of films) 
SELECT *
FROM
  (SELECT yr,
          COUNT(*) AS cnt
   FROM movie
   INNER JOIN casting ON movie.id = casting.movieid
   INNER JOIN actor ON casting.actorid = actor.id
   WHERE name = 'Bruce Willis'
   GROUP BY yr
   ORDER BY cnt DESC)
WHERE ROWNUM = 1;

-- q14 List the directors, who have starred in films they directed along with the number of those films each has starred in and the year the earliest was made (in descending order of year)

-- INTERPRETED AS: List all directors who have starred in films that they directed, along with the total number of films they have starred in (whether they directed it or not), along with the year of the earliest film they starred in or directed
SELECT a2.name,
       MIN(m2.yr) AS firstFilm,
       COUNT(*) AS starredIN
FROM actor a2
INNER JOIN casting c2 ON a2.id = c2.actorid
INNER JOIN movie m2 ON m2.id = c2.movieid
WHERE c2.actorid IN
    (SELECT director.id
     FROM actor director
     INNER JOIN movie m1 ON m1.director = director.id
     INNER JOIN casting c1 ON m1.id = c1.movieid
     INNER JOIN actor a1 ON c1.actorid = a1.id
     WHERE a1.id = director.id
       AND c1.ord = 1)
GROUP BY a2.name;

-- q15 List the names of actors who have appeared in at least three films directed by Alfred Hitchcock along with the number of those films each has starred in (in descending order of number of films)
SELECT a1.name,
       COUNT(*) AS starredIn
FROM actor a1
INNER JOIN casting c1 ON a1.id = c1.actorid
INNER JOIN movie m1 ON m1.id = c1.movieid
INNER JOIN actor director ON m1.director = director.id
WHERE director.name = 'Alfred Hitchcock'
GROUP BY a1.name HAVING COUNT(*) >= 3
ORDER BY starredIn DESC;

-- q16 List the title, director’s name, co-star (ord = 2), year and score (in descending order of score) for the five best films starring Robert De Niro
SELECT *
FROM
  (SELECT m1.title,
          d.name AS director,
          a2.name AS coStar,
          m1.yr,
          m1.score
   FROM movie m1
   INNER JOIN actor d ON d.id = m1.director
   INNER JOIN casting c1 ON c1.movieid = m1.id
   INNER JOIN actor a1 ON c1.actorid = a1.id
   INNER JOIN casting c2 ON c2.movieid = m1.id
   INNER JOIN actor a2 ON c2.actorid = a2.id
   WHERE a1.name = 'Robert De Niro'
     AND c1.ord = 1
     AND c2.ord = 2
   ORDER BY m1.score DESC) t
WHERE ROWNUM <= 5;

-- q17 Find the actor(s) who has appeared in most films, but has never starred in one
SELECT name
FROM
  (SELECT name,
          appearances,
          MAX(appearances) OVER () AS highest
   FROM
     (SELECT a1.name,
             COUNT(*) AS appearances
      FROM actor a1
      INNER JOIN casting c1 ON a1.id = c1.actorid
      INNER JOIN movie m1 ON m1.id = c1.movieid
      GROUP BY a1.name HAVING MIN(c1.ord) <> 1
      ORDER BY appearances DESC) t) t2
WHERE appearances = highest;

-- q18 List the five actors with the longest careers (the time between their first and last film). For each one give their name, and the length of their career (in descending order of career length)
SELECT name,
       diff AS careerLength
FROM
  (SELECT a1.name,
          MAX(m1.yr) - MIN(m1.yr) AS diff
   FROM movie m1
   INNER JOIN casting c1 ON c1.movieid = m1.id
   INNER JOIN actor a1 ON a1.id = c1.actorid
   GROUP BY a1.name
   ORDER BY diff DESC)
WHERE ROWNUM <= 5;

-- q19 List the 10 best directors (use the average score of their films to determine who is best) in descending order along with the number of films they’ve made and the average score for their films. Only consider directors who have made at least five films
SELECT name,
       averageScore,
       filmsMade
FROM
  (SELECT director.name,
          AVG(m1.score) AS averageScore,
          COUNT(*) AS filmsMade
   FROM actor director
   INNER JOIN movie m1 ON m1.director = director.id
   GROUP BY director.name HAVING COUNT(*) >= 5
   ORDER BY averageScore DESC) t
WHERE ROWNUM <= 10;

-- q20 List the decades from the 30s (1930-39) to the 90s (1990-99) and for each of those decades show the average film score, the best film and the actor who starred in most films
SELECT m1.title AS bestFilm,
       t.average,
       t.decade,
       t2.name AS mostStarredActor
FROM movie m1
INNER JOIN
  (SELECT FLOOR(yr/10) * 10 AS decade,
          AVG(score) AS average,
          MAX(score) AS highest
   FROM movie
   WHERE yr BETWEEN 1930 AND 1999
   GROUP BY FLOOR(yr/10) * 10) t ON t.highest = m1.score
AND t.decade = FLOOR(yr/10) * 10
INNER JOIN
  (SELECT name,
          decade,
          actedIn
   FROM
     (SELECT name,
             decade,
             actedIn,
             MAX(actedIn) OVER (PARTITION BY decade) AS topActed
      FROM
        (SELECT a1.name,
                FLOOR(yr/10) * 10 AS decade,
                COUNT(*) AS actedIn
         FROM movie m1
         INNER JOIN casting c1 ON c1.movieid = m1.id
         INNER JOIN actor a1 ON a1.id = c1.actorid
         WHERE c1.ord = 1
         GROUP BY a1.name,
                  FLOOR(yr/10) * 10) t) t2
   WHERE actedIn = t2.topActed) t2 ON t2.decade = t.decade
ORDER BY t.decade DESC;
