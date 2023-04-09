-- Q1: amount of alcohol in the best beers
-- Defines a view which displays a list of top-rated beers, their container 
-- size and type, and their respective ABV values. This view accesses the beers 
-- table and uses the 'WHERE' keyword to check if the rating threshold is met. 
-- The 'CONCAT' function is used to combine the text for the container volume, 
-- the string 'ml ', and the container type.  

CREATE OR REPLACE VIEW Q1(beer, "sold in", alcohol) AS
SELECT  beers.name AS beer, CONCAT(beers.volume, 'ml ', beers.sold_in) AS "sold in",
        CONCAT(ROUND(((beers.volume * beers.abv) / 100)::numeric, 1), 'ml') AS alcohol
FROM    beers
WHERE   beers.rating > 9;

-- Q2: beers that don't fit the ABV style guidelines
-- Defines a view which displays beers with ABV (alcohol by volume) values that 
-- are outside the acceptable range specified for their respective styles. 
-- This view accesses the beers and styles tables to retrieve relevant 
-- name, style and ABV information, and uses a CASE statement to determine 
-- what beers are out-of-style.

CREATE OR REPLACE VIEW Q2(beer, style, abv, reason) AS
SELECT  beers.name AS beer, styles.name AS style, beers.abv,
        CASE
            WHEN beers.abv < styles.min_abv THEN
                CONCAT('too weak by ', ROUND(CAST((styles.min_abv - beers.abv) AS numeric(4,1)), 1), '%')
            WHEN beers.abv > styles.max_abv THEN
                CONCAT('too strong by ', ROUND(CAST((beers.abv - styles.max_abv) AS numeric(4,1)), 1), '%')
        END AS reason

FROM    beers
JOIN    styles ON beers.style = styles.id
WHERE   beers.abv > styles.max_abv OR beers.abv < styles.min_abv;

-- Q3: Number of beers brewed in each country
-- Defines a view which displays a list of all countries and the corresponding 
-- number of beers brewed in each country. This view accesses the countries, 
-- brewed_by, breweries, and locations tables, joining them together to 
-- reference each beer with its respective country.

CREATE OR REPLACE VIEW Q3(country, "#beers") AS
SELECT  countries.name AS country, COUNT(brewed_by.beer) AS "#beers"
FROM    countries
LEFT JOIN (
    SELECT  locations.within, brewed_by.beer AS beer
    FROM    brewed_by
    JOIN    breweries ON brewed_by.brewery = breweries.id
    JOIN    locations ON breweries.located_in = locations.id
) AS brewed_by ON countries.id = brewed_by.within
GROUP BY    countries.name;

-- Q4: Countries where the worst beers are brewed
-- Defines a view which gives information about the worst beers in the world. 
-- This view accesses and manipulates the beers, breweries, brewed_by, and 
-- countries tables to display the beer name, brewery, and country for beers 
-- with a rating less than 3. 

CREATE OR REPLACE VIEW Q4(beer, brewery, country) AS
SELECT  beers.name AS beer, breweries.name AS brewery, countries.name AS country
FROM    beers
JOIN    brewed_by ON beers.id = brewed_by.beer
JOIN    breweries ON brewed_by.brewery = breweries.id
JOIN    locations ON breweries.located_in = locations.id
JOIN    countries ON locations.within = countries.id
WHERE   beers.rating < 3;

-- Q5: Beers that use ingredients from the Czech Republic
-- Defines a view which lists the beer name, ingredients, and ingredient types
-- for beers which use ingredients originating from the Czech Republic. This 
-- view accesses the beers, contains, ingredients, and countries tables, 
-- joining them in accordance with their foreign key relationships.

CREATE OR REPLACE VIEW Q5(beer, ingredient, "type") AS
SELECT  beers.name AS beer, ingredients.name AS ingredient, ingredients.itype AS type
FROM    beers
JOIN    contains ON beers.id = contains.beer
JOIN    ingredients ON contains.ingredient = ingredients.id
JOIN    countries ON ingredients.origin = countries.id
WHERE   countries.name = 'Czech Republic';

-- Q6: Beers containing the most used hop and the most used grain
-- Defines a view which lists beers that contain both the most commonly used 
-- hop and the most commonly used grain. It accesses the beers, contains, and 
-- ingredients tables, using subqueries to determine the most popular hop and
-- grain ingredients. 

CREATE OR REPLACE VIEW Q6(beer) AS
SELECT  beers.name AS beer
FROM    beers
WHERE EXISTS (
    SELECT 1 FROM contains JOIN ingredients ON contains.ingredient = ingredients.id
    WHERE beers.id = contains.beer AND ingredients.itype = 'hop' AND ingredients.name = (
        -- This subquery finds the most popular hop by grouping hops, counting
        -- their occurrences, ordering by count, and selecting the top result
        -- using the 'Limit 1' clause.
        SELECT  ingredients.name FROM ingredients JOIN contains ON ingredients.id = contains.ingredient
        WHERE   ingredients.itype = 'hop'
        GROUP BY ingredients.name
        ORDER BY COUNT(*) DESC
        LIMIT 1
    )
) AND EXISTS (
    SELECT 1 FROM contains JOIN ingredients ON contains.ingredient = ingredients.id
    WHERE beers.id = contains.beer AND ingredients.itype = 'grain' AND ingredients.name = (
        -- This subquery finds the most popular grain by grouping grains, counting
        -- their occurrences, ordering by count, and selecting the top result 
        -- using the 'Limit 1' clause
        SELECT  ingredients.name FROM ingredients JOIN contains ON ingredients.id = contains.ingredient
        WHERE   ingredients.itype = 'grain'
        GROUP BY ingredients.name
        ORDER BY COUNT(*) DESC
        LIMIT 1
    )
);

-- Q7: Breweries that make no beer
-- Defines a view with a single column named "brewery". This view displays the
-- names of breweries from the breweries table that do not have any beers
-- associated with them in the brewed_by table.

CREATE OR REPLACE VIEW Q7(brewery) AS
SELECT  breweries.name AS brewery
FROM    breweries
WHERE NOT EXISTS (
        SELECT FROM brewed_by
        WHERE   breweries.id = brewed_by.brewery
    );

-- Q8: Function to give "full name" of beer
-- This function takes an integer paramter, beer_id, and returns the full name 
-- of the associated beer. The full name is generated by using a regular 
-- expression to filter extraneous brewery terms from the brew term. If the 
-- beer_id does not reference a beer in the database, this function returns the
-- string 'No such beer'. 

CREATE OR REPLACE FUNCTION Q8(beer_id integer) RETURNS TEXT
AS $$
DECLARE
    full_name TEXT;
BEGIN
    -- Create a temporary table (filtered_breweries) to hold brewery names
    WITH filtered_breweries AS (
        SELECT breweries.name,
            -- Remove restricted terms and trim extra spaces
            TRIM(
                REGEXP_REPLACE(REGEXP_REPLACE(breweries.name, ' (Beer|Brew).*$', ''), '\s+', ' ')
            ) AS processed_name
        
        FROM    beers
        JOIN    brewed_by ON beers.id = brewed_by.beer
        JOIN    breweries ON brewed_by.brewery = breweries.id
        WHERE   beers.id = beer_id
    )

    -- Concatenate brewery names and the beer name
    SELECT      STRING_AGG(filtered_breweries.processed_name, ' + ' ORDER BY filtered_breweries.name) || ' ' || beers.name
    INTO        full_name
    FROM        beers, filtered_breweries
    WHERE       beers.id = beer_id
    GROUP BY    beers.name;

    -- Return either the concatenated full_name or 'No such beer' if no match
    IF full_name IS NULL THEN
        RETURN 'No such beer';
    ELSE
        RETURN full_name;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Q9: Beer data based on partial match of beer name
-- This function takes a string as an argument and searches for beers with names
-- that contain  that string somewhere in their name. The function returns the 
-- beer name, a concatenated list of breweries producing the beer, and 
-- information about hops, grains, and extras used in the beer. The function 
-- accesses the beers, brewed_by, breweries, contains, and ingredients tables to
-- gather the relevant information.

DROP TYPE IF EXISTS BeerData CASCADE;
CREATE TYPE BeerData AS (beer TEXT, brewer TEXT, info TEXT);

CREATE OR REPLACE FUNCTION Q9(partial_name TEXT) RETURNS SETOF BeerData
AS
$$
BEGIN
    -- RETURN QUERY statement will return a query result set as its output
    RETURN QUERY
        SELECT  beers.name AS beer,
            STRING_AGG(DISTINCT breweries.name, ' + ' ORDER BY breweries.name) AS brewer,
            TRIM(TRAILING E'\n' FROM CONCAT(
                -- Use STRING_AGG to create three separate lists for hops, 
                -- grains, and extras (adjuncts). COALESCE function is used to 
                -- handle cases where there are no ingredients.
                
                COALESCE('Hops: ' || STRING_AGG(DISTINCT ingredients.name, ',' 
                        ORDER BY ingredients.name) 
                        FILTER (WHERE ingredients.itype = 'hop') || E'\n', ''),
                
                COALESCE('Grain: ' || STRING_AGG(DISTINCT ingredients.name, ',' 
                        ORDER BY ingredients.name) 
                        FILTER (WHERE ingredients.itype = 'grain')  || E'\n', ''),
                
                COALESCE('Extras: ' || STRING_AGG(DISTINCT ingredients.name, ',' 
                        ORDER BY ingredients.name) 
                        FILTER (WHERE ingredients.itype = 'adjunct') || E'\n', '')
            )) AS info
        
        -- Join the appropriate tables to retrieve brewers and ingredients for 
        -- each beer
        FROM    beers
        JOIN    brewed_by ON beers.id = brewed_by.beer
        JOIN    breweries ON brewed_by.brewery = breweries.id
        LEFT JOIN contains ON beers.id = contains.beer
        LEFT JOIN ingredients ON contains.ingredient = ingredients.id
        
        -- Filter based on the string provided as an argument
        WHERE       LOWER(beers.name) LIKE '%' || LOWER(partial_name) || '%'
        GROUP BY    beers.id, beers.name
        ORDER BY    beers.name;
END;
$$ LANGUAGE plpgsql;


