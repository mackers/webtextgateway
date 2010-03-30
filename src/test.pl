#!/bin/perl

use Net::SMS::Clickatell;
use strict;
use warnings;

my $catell = Net::SMS::Clickatell->new( API_ID => "3137700" );
my $logged_in = $catell->auth( USER => "mackers", PASSWD => "cha2rB" );

print "logged_in = $logged_in\n";


my $retval = $catell->sendmsg( TO => "34636685421", MSG => 'Hi, I\'m using Clickatell.pm' );

print "retval = $retval\n";
print "err = " .  $catell->error . "\n";


