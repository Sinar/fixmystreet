package FixMyStreet::SendReport::Email::TfL;

use Moo;
extends 'FixMyStreet::SendReport::Email::SingleBodyOnly';

has contact => (
    is => 'ro',
    default => 'Traffic lights'
);

1;
