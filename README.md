# Queries and Functions on BeerDB	
Utilise SQL queries (packaged as views) and PlpgSQL functions to build some useful data access operations on BeerDB, an extensive database detailing beer styles, ingredients, breweries and recipes. A basic ER model of BeerDB is shown below:

![image](https://user-images.githubusercontent.com/129048872/230734966-5176e679-0a9e-40b4-88f9-e466aec3e948.png)

Output examples:

Query 1:
select * from q1 order by beer;
               beer                |   sold in    | alcohol 
-----------------------------------+--------------+---------
 Breakfast Stout                   | 355ml bottle | 29.5ml
 Double Red IPA                    | 355ml can    | 30.2ml
 Double Red IPA                    | 355ml can    | 28.4ml
 Frozen Sea                        | 375ml can    | 31.9ml
 Hops-In-A-Can                     | 473ml can    | 49.7ml
 Jumping The Shark 2013            | 375ml bottle | 57.7ml
 Jumping The Shark 2013/2021       | 375ml bottle | 58.5ml
 Jumping The Shark 2015            | 375ml bottle | 69.0ml
 Jumping The Shark 2019            | 375ml bottle | 45.4ml
 Lark Barrel-Aged Imperial Jsp III | 440ml can    | 56.3ml
 Matt                              | 355ml bottle | 44.4ml
 Narwhal (Ba)                      | 473ml can    | 54.4ml
 Noa (Pecan Mud)                   | 330ml bottle | 36.3ml
 Sculpin                           | 355ml can    | 24.9ml
 Sink The Bismarck                 | 375ml bottle | 153.8ml
 Sunrise Valley                    | 440ml can    | 35.2ml
 Tactical Nuclear Penguin          | 375ml bottle | 120.0ml
 Victory At Sea                    | 355ml bottle | 35.5ml
 Whisky Aged Cider                 | 750ml bottle | 73.5ml
 Yakima Valley                     | 440ml can    | 35.2ml
 Zamboni Haze                      | 473ml can    | 37.8ml
