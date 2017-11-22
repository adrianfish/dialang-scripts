#!/usr/bin/perl

use strict;

use DBI;

my $dbh = DBI->connect('DBI:Pg:dbname=DIALANG;host=localhost;port=5432', 'postgres', '',
                {AutoCommit => 1})
                    or die("Failed to connect to database");

my $locale = 'eng_gb';

my $sql = "SELECT DISTINCT basket_id FROM booklet_basket WHERE booklet_id IN (SELECT booklet_id FROM preest_assignments WHERE tl = '$locale') ORDER BY basket_id;";
my $basket_ids = $dbh->selectcol_arrayref($sql);

my $answers_sth = $dbh->prepare("SELECT * FROM answers WHERE item_id IN (SELECT item_id FROM basket_item WHERE basket_id = ?)");

print "Basket ID|Type|Skill|Label|Prompt|Gap Text|Weight|Media Type|Text Media|File Media|Answers\n";

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
    $answers_sth->execute($basket_id);
    my $answer_texts = '';
    my %answers = %{$answers_sth->fetchall_hashref('id')};
    foreach my $answer_id (keys(%answers)) {
        my $answer = $answers{$answer_id};
        $answer_texts .= '#' . $answer->{'text'};
    }
    print "$basket_id|$type|$skill|$label|$prompt|$gaptext|$weight|$mediatype|$textmedia|$filemedia|$answer_texts\n";
}

$dbh->disconnect;
