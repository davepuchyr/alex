# $Id: procmailrc.pm 247 2008-12-05 00:03:45Z dave $
# NOTE: procmail does NOT process local mail, so testing locally has to be
#       done with echo -e "To: dave\nFrom: me\n\netc" | ~/.procmailrc.pl.

sub onHeader {
}


sub onBodyLine {
   my $line = ${+ shift };

   if ( $line =~ m|procmailTest|o ) {
      return \&procmailTest;
   } elsif ( $line =~ m|fake-directory.eu/refresh|o ) {
      require '.procmailrc.d/ebay.pm';
      return \&procmail;
   }
}


sub procmailTest { # cannot be tested locally!
   my $head = ${+ shift };
   my $body = ${+ shift };
   my $line = ${+ shift };

   local $/;
   my $remaining = <STDIN>;

   return !print $head . "functorified\n\n" . $body . $remaining;
}

1;

