# $Id: ENV.common.pm 120 2010-10-10 17:47:05Z dave $

# db
$ENV{DB_ULYZ_EBAY} = 'ebay'; # could add if ( !exists( $ENV{DB_ULYZ_EBAY} ) );
$ENV{DB_ULYZ_PORT} = 3306;
$ENV{DB_ULYZ_USER} = 'dave';
$ENV{DB_ULYZ_PASSWORD} = 'xxx' if ( !exists( $ENV{DB_ULYZ_PASSWORD} ) );

# eventd
$ENV{EVENTD_LOG_DIR} = '';
$ENV{EVENTD_LOG_FILE} = 'eventd.log';

# executables
$ENV{EXE_BIDDER} = 'bidder.pl';
$ENV{EXE_REAPER} = 'reaper.pl';
$ENV{EXE_SEARCHER} = 'searcher.pl';

# command keys
$ENV{CMD_KEY_ACCOUNT} = 'account';
$ENV{CMD_KEY_AUCTION} = 'auction';
$ENV{CMD_KEY_BID} = 'bid';
$ENV{CMD_KEY_BID_MAX} = 'max';
$ENV{CMD_KEY_BID_STRATEGY} = 'bid_strategy';
$ENV{CMD_KEY_DURATION} = 'duration';
$ENV{CMD_KEY_EXE} = 'exe';
$ENV{CMD_KEY_MAILTO} = 'email';
$ENV{CMD_KEY_SITE} = 'site';
$ENV{CMD_KEY_URL} = 'url';
$ENV{CMD_KEY_VERBOSE} = 'verbose';
$ENV{CMD_KEY_WD} = 'wd'; # working directory

# eBayAPI.pm
$ENV{DEVELOPER_DELIMITER} = ',';

# Scheduler.pm
$ENV{SCHEDULER_MIN_HOURS_TIL_END} = 3; # minimum number of hours between the penultimate bid and auction end
$ENV{SCHEDULER_NUDGE} = 3600; # maximum number of seconds to bump the penultimate bid away from and ultimate bid closer to the end

# bidder.pl
$ENV{BIDDER_BID_STRATEGIES_DELIMITER} = ',';
# dups in strategies ARE allowed; probability of a particular strategy being used == a function of the number of times it is included
$ENV{BIDDER_BID_STRATEGIES_INITIAL} = 'BidViaSearch'; # BIDDER_BID_STRATEGIES_DELIMITER delimited initial (1st) bid strategies, eg seller's other items, etc
$ENV{BIDDER_BID_STRATEGIES_SUBSEQUENT} = 'BidViaMyEbayActive,BidViaMyEbayActive,BidViaMyEbayActiveUntilWinning'; # BIDDER_BID_STRATEGIES_DELIMITER delimited subsequent bid strategies, eg BidViaEmailAlert, BidViaMyEbayActiveLowBall, etc
$ENV{BIDDER_BID_STRATEGIES_FINAL} = 'BidViaMyEbayActiveUntilWinning'; # BIDDER_BID_STRATEGIES_DELIMITER delimited subsequent bid strategies, eg BidViaMyEbayUntilWinning, etc

1;

