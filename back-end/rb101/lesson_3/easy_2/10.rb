# If we had a 40 character wide table of Flintstone family members, how could we
# easily center that title above the table with spaces?

title = "Flintstone Family Members"

" " * ((40 - title.length) / 2) + title
title.center(40)
