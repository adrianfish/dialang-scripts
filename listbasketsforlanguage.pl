#!/usr/bin/perl

use strict;

use DBI;

my $dbh = DBI->connect('DBI:Pg:dbname=DIALANG;host=localhost;port=5432', 'postgres', '',
                {AutoCommit => 1})
                    or die("Failed to connect to database");

my $locale = 'eng_gb';

my $sql = "SELECT DISTINCT basket_id FROM booklet_basket WHERE booklet_id IN (SELECT booklet_id FROM preest_assignments WHERE tl = '$locale') ORDER BY basket_id;";
my $basket_ids = $dbh->selectcol_arrayref($sql);

print "Type|Skill|Label|Prompt|Gap Text|Weight|Media Type|Text Media|File Media\n";

foreach my $basket_id (@$basket_ids) {
    my $basket = $dbh->selectrow_hashref("SELECT * FROM baskets WHERE id = '$basket_id'");

    my $type = $basket->{'type'};
    my $skill = $basket->{'skill'};
    my $label = $basket->{'label'};
    my $prompt = $basket->{'prompt'};
    my $gaptext = $basket->{'gaptext'};
    my $weight = $basket->{'weight'};
    my $mediatype = $basket->{'mediatype'};
    my $textmedia = $basket->{'textmedia'};
    my $filemedia = $basket->{'filemedia'};
    print "$type|$skill|$label|$prompt|$gaptext|$weight|$mediatype|$textmedia|$filemedia\n";
}

$dbh->disconnect;
