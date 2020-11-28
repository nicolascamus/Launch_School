# Remove everything starting from "house"
# make the return value "Few things in life are as important as ".
# But leave the advice variable as "house training your pet dinosaur.".

advice = "Few things in life are as important as house training your pet "\
         "dinosaur."

advice.slice!(/.*(?=house)/)
