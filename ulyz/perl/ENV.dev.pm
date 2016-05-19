# $Id: ENV.dev.pm 117 2010-10-01 12:13:47Z dave $

require 'ENV.common.pm';


# db
$ENV{DB_ULYZ_HOST} = 'duo';

# ebay
$ENV{EBAY_API_URL} = 'https://api.sandbox.ebay.com/ws/api.dll';
# dmjp: LWP and polipo don't play well together $ENV{EBAY_PROXY} = 'http://duo:3128';

# ghost.pl
$ENV{GHOST_MIN_DURATION} = 3; # minimum auction duration in days for an auction to be eligible for ghost bidding
$ENV{GHOST_MAX_DURATION} = 99; # maximum auction duration in days for an auction to be eligible for ghost bidding
$ENV{GHOST_ELIGIBLE_THUMBS} = '41007087008080_0.jpg';
$ENV{GHOST_MIN_SAMPLES} = 1; # minimum number of price samples in average price

# eventd
$ENV{EVENTD_PERIOD} = 59; # seconds to sleep in main loop; can't be too long or we lose the db conn

# netmorpher
$ENV{NM_HOST} = 'duo';
$ENV{NM_PORT} = 9000;

# user.js.pl
$ENV{USER_JS_USER} = 'jsa';

1;

