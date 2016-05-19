package Decoder;
# $Id: Decoder.pm 10 2009-11-13 17:02:20Z dave $

sub decodeDescription {
   my $desc = shift;
   # Hello Dave,
   # what about this:
   # <span id=LastRevision style='display:none;'>20091023-1935</span>
   #
   # In this tag, we parse ABCDEFGH-IJKL but only use IJKL at the moment.
   #
   # Our formula would be IK*JL, which allows max bids up to 2475 EUR/GBP
   # (25*99). The other 8 digits will be left for future use (like how many
   # bidders, or the preferred bidders' country, or something in that
   # sense.
   #
   # Also, it would be cool if we could manually send messages to the
   # server (by email) with something like 180427849462-20091023-2215 (the
   # ebay auction number followed by the max bid code), allowing us to
   # overide the initial max bid during the auction, or even to request the
   # robot to bid on another seller's auction with max bid = 21*25 = 525.
   #
   # Tell me if this makes sense. If yes, I can implement it in our
   # listings right away - piece of cake.
   # Thanks
   # Alex
   my ( $I, $J, $K, $L ) = $desc =~ m|\d{8}-(\d)(\d)(\d)(\d)|;
   #printf( "$I $J $K $L => $I$K * $J$L = %d ", int( "$I$K" ) * int( "$J$L" ) );

   return defined( $I ) && defined( $J ) && defined( $K ) && defined( $L ) ? int( "$I$K" ) * int( "$J$L" ) : 0;
}

1;

