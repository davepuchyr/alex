#!/usr/bin/perl -w

use strict;
use ENV;
use Utils;
use open qw(:std :utf8);

$| = 1;

my $root = 'firefox'; # HARD-CODED
mkdir( $root ) or die "$!" if ( !-d $root );

my $dbh = Utils::getDBH();
my $sql =<<EOS;
SELECT account, proxy, agent, site
FROM accounts
WHERE account != ''
AND banned != 1
ORDER BY account
EOS
my $sth = $dbh->prepare( $sql ) or die "couldn't prepare: $dbh->errstr\n";
$sth->execute() or die "couldn't execute: $sth->errstr\n";

my ( $profiles, $i ) = ( "$root/profiles.ini", 0 );
open( PROFILES, '>:utf8', $profiles ) or die "couldn't open $profiles: $!\n";
print PROFILES <<EOS;
[General]
StartWithLastProfile=0

[Profile$i]
Name=default
IsRelative=1
Path=default
EOS

while ( my ( $account, $proxy, $agent, $site ) = $sth->fetchrow_array() ) {
   my ( $host, $port ) = $proxy =~ m|http://(.*):(\d+)|;
   my $dir = "$root/$account";
   mkdir( $dir ) or die "$!" if ( !-d $dir );

   my $file = "$dir/user.js"; # HARD-CODED
   open( OUT, '>:utf8', $file ) or die "couldn't open $file: $!\n";
   print "$account...";
   print OUT <<EOS;
// $account $proxy $agent
// important
user_pref("browser.startup.page", 1);
user_pref("browser.startup.homepage", "http://dual.anoxymous.com/x/env?site=$site&whoami=$account");
user_pref("general.useragent.override", "$agent");
user_pref("network.proxy.type", 1);
user_pref("network.proxy.ftp", "$host");
user_pref("network.proxy.ftp_port", $port);
user_pref("network.proxy.gopher", "$host");
user_pref("network.proxy.gopher_port", $port);
user_pref("network.proxy.http", "$host");
user_pref("network.proxy.http_port", $port);
user_pref("network.proxy.share_proxy_settings", true);
user_pref("network.proxy.socks", "$host");
user_pref("network.proxy.socks_port", $port);
user_pref("network.proxy.ssl", "$host");
user_pref("network.proxy.ssl_port", $port);
// convenience
user_pref("permissions.default.image", 2); // block ALL images; use "3" to block 3rd party images
user_pref("security.enable_java", false);
user_pref("browser.tabs.warnOnClose", false);
user_pref("browser.tabs.warnOnOpen", false);
user_pref("layout.spellcheckDefault", 0);
user_pref("general.warnOnAboutConfig", false);
user_pref("browser.backspace_action", 0);
user_pref("security.warn_viewing_mixed", false);
user_pref("accessibility.typeaheadfind", true);
user_pref("general.smoothScroll", false);
// http://www.mozilla.org/unix/customizing.html#prefs
// Image animation mode: normal, once, none.
// This pref now has UI under Privacy & Security->Images.
user_pref("image.animation_mode", "none");
// Middle mouse prefs: true by default on Unix, false on other platforms.
user_pref("middlemouse.paste", true);
user_pref("middlemouse.openNewWindow", true);
user_pref("middlemouse.contentLoadURL", false);
user_pref("middlemouse.scrollbarPosition", false);
EOS
   close( OUT ) or die "couldn't close $file: $!\n";

   my $feedback = `js $file 2>&1`;
   die "\n\ntrouble: $feedback" if ( $feedback !~ m|ReferenceError: user_pref is not defined| );

   ++$i;
   print PROFILES <<EOS;

[Profile$i]
Name=$account
IsRelative=1
Path=$account
EOS
}

close( PROFILES ) or die "couldn't close $profiles: $!\n";

$sth->finish() or die "couldn't finish: $sth->errstr\n";
$dbh->disconnect() or die "couldn't disconnect: $!\n";

my $user = $ENV{USER_JS_USER};
exit !print <<EOS;
done.  Now do:
su -
cd /home/$user/.mozilla/firefox
rsync --exclude default --delete -avP $ENV{PWD}/$root/. . # rsync once to setup directories...
for i in `ls -1 | fgrep -v . | fgrep -v default | xargs`; do cd \$i; rsync -avP --exclude \*.sqlite --exclude Cache ../default/. .; cd ..; done
rsync --exclude default          -avP $ENV{PWD}/$root/. . # ...rsync again to sync user.js
if [ "$ENV{USER}" != "$ENV{USER_JS_USER}" ]; then chown -R $user.$user .; fi
EOS
# NOTE: important escaping of $i in the bash loop above!

