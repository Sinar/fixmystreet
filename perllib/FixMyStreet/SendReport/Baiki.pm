package FixMyStreet::SendReport::Baiki;

use Moose;

BEGIN { extends 'FixMyStreet::SendReport::Email'; }

sub send {
    my $self = shift;
    my ( $row, $h ) = @_;

    my @recips = $self->build_recipient_list( $row, $h );

    # on a staging server send emails to ourselves rather than the bodies
    if (mySociety::Config::get('STAGING_SITE') && !mySociety::Config::get('SEND_REPORTS_ON_STAGING') && !FixMyStreet->test_mode) {
        @recips = ( mySociety::Config::get('CONTACT_EMAIL') );
    }

    unless ( @recips ) {
        $self->error( 'No recipients' );
        return 1;
    }
    $h->{id} = (split(/\//, $h->{url}))[0];

    my ($verbose, $nomail) = CronFns::options();
    my $result = FixMyStreet::App->send_email_cron(
        {
            _template_ => $self->get_template( $row ),
            _parameters_ => $h,
            _line_indent => $row->cobrand eq 'zurich' ? '' : undef, # XXX Access to Cobrand module here?
            To => $self->to,
            From => $self->send_from( $row ),
        },
        mySociety::Config::get('CONTACT_EMAIL'),
        \@recips,
        $nomail
    );

    if ( $result == mySociety::EmailUtil::EMAIL_SUCCESS ) {
        $self->success(1);
    } else {
        $self->error( 'Failed to send email' );
    }

    return $result;
}

1;
