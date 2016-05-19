# $Id: ENV.prod.pm 109 2010-07-28 11:33:33Z dave $

require 'ENV.common.pm';


# db
$ENV{DB_ULYZ_HOST} = 'localhost';
$ENV{DB_ULYZ_PASSWORD} = 'xxxx';

# ebay
$ENV{EBAY_API_URL} = 'https://api.ebay.com/ws/api.dll';
#$ENV{EBAY_PROXY} = 'http://hannibal:3128';

# ghost.pl
$ENV{GHOST_MIN_DURATION} = 3; # minimum auction duration in days for an auction to be eligible for ghost bidding
$ENV{GHOST_MAX_DURATION} = 7; # maximum auction duration in days for an auction to be eligible for ghost bidding
$ENV{GHOST_ELIGIBLE_THUMBS} = 'S250-th.jpg, S270-th.jpg, S300-th.jpg, S330-th.jpg, S360-th.jpg, S400-th.jpg, S430-th.jpg';
#$ENV{GHOST_INELIGIBLE_COUNTRIES} = 'FR'; # problematic ebay ccTLDs
$ENV{GHOST_MIN_SAMPLES} = 10; # minimum number of price samples in average price

# eventd
$ENV{EVENTD_PERIOD} = 300; # seconds to sleep in main loop; can't be too long or we lose the db conn

# netmorpher
$ENV{NM_HOST} = 'www';
$ENV{NM_PORT} = 9010;

# user.js.pl
$ENV{USER_JS_USER} = 'alex';

1;

