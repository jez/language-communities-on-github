select
  language,
  avg(thumbsup),
  avg(thumbsdown),
  avg(laugh),
  avg(hooray),
  avg(confused),
  avg(heart),
  avg(total_count),
  avg((total_count * 1.0) / (comments / 100.0)) as "Emoji per 100 Comments"
from reactions
group by language
