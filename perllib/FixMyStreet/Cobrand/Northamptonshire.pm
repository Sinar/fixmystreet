package FixMyStreet::Cobrand::Northamptonshire;
use parent 'FixMyStreet::Cobrand::Whitelabel';

use strict;
use warnings;

use Moo;
with 'FixMyStreet::Roles::ConfirmValidation';

sub council_area_id { 2234 }
sub council_area { 'Northamptonshire' }
sub council_name { 'Northamptonshire County Council' }
sub council_url { 'northamptonshire' }

sub enter_postcode_text { 'Enter a Northamptonshire postcode, street name and area, or check an existing report number' }

sub disambiguate_location {
    my $self    = shift;
    my $string  = shift;

    return {
        %{ $self->SUPER::disambiguate_location() },
        centre => '52.30769080650276,-0.8647071378799923',
        bounds => [ 51.97726778979222, -1.332346116362747, 52.643600776698605, -0.3416080408721255 ],
    };
}

sub categories_restriction {
    my ($self, $rs) = @_;
    return $rs->search( [ { 'body.name' => 'Northamptonshire County Council' } ], { join => { body => 'body_areas' } });
}

sub send_questionnaires { 0 }

sub on_map_default_status { 'open' }

sub report_sent_confirmation_email { 'id' }

sub problems_on_map_restriction {
    my ($self, $rs) = @_;
    # Northamptonshire don't want to show district/borough reports
    # on the site
    return $self->problems_restriction($rs);
}

sub privacy_policy_url {
    'https://www3.northamptonshire.gov.uk/councilservices/council-and-democracy/transparency/information-policies/privacy-notice/place/Pages/street-doctor.aspx'
}

sub is_two_tier { 1 }

sub get_geocoder { 'OSM' }

sub map_type { 'OSM' }

sub open311_config {
    my ($self, $row, $h, $params) = @_;

    my $extra = $row->get_extra_fields;

    # remove the emergency category which is informational only
    @$extra = grep { $_->{name} ne 'emergency' } @$extra;

    push @$extra,
        { name => 'report_url',
          value => $h->{url} },
        { name => 'title',
          value => $row->title },
        { name => 'description',
          value => $row->detail },
        { name => 'category',
          value => $row->category };

    $row->set_extra_fields(@$extra);

    $params->{multi_photos} = 1;
}

sub report_validation {
    my ($self, $report, $errors) = @_;

    if ( length( $report->title ) > 120 ) {
        $errors->{title} = sprintf( _('Summaries are limited to %s characters in length. Please shorten your summary'), 120 );
    }
}

1;
