# $Id: ENV.pm 101 2010-05-14 20:33:06Z dave $

# db
$ENV{DB_ULYZ} = 'ulyz'; # could add if ( !exists( $ENV{DB_ULYZ_EBAY} ) );
$ENV{DB_ULYZ_HOST} = 'duo';
$ENV{DB_ULYZ_PORT} = 3306;
$ENV{DB_ULYZ_USER} = 'dave';
$ENV{DB_ULYZ_PASSWORD} = 'xxx' if ( !exists( $ENV{DB_ULYZ_PASSWORD} ) );

# netmorpher
$ENV{NM_HOST} = '10.13.13.12';
$ENV{NM_PORT} = 9001;
$ENV{SKYPE_USER} = 'dave';
$ENV{SKYPE_HOST} = 'localhost';

1;

