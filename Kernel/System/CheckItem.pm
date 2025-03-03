# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2022 Rother OSS GmbH, https://otobo.de/
# --
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# --

package Kernel::System::CheckItem;

use strict;
use warnings;

use Email::Valid;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
);

=head1 NAME

Kernel::System::CheckItem - check items

=head1 DESCRIPTION

All item check functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $CheckItemObject = $Kernel::OM->Get('Kernel::System::CheckItem');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 CheckError()

get the error of check item back

    my $Error = $CheckItemObject->CheckError();

=cut

sub CheckError {
    my $Self = shift;

    return $Self->{Error};
}

=head2 CheckErrorType()

get the error's type of check item back

    my $ErrorType = $CheckItemObject->CheckErrorType();

=cut

sub CheckErrorType {
    my $Self = shift;

    return $Self->{ErrorType};
}

=head2 CheckEmail()

returns true if check was successful, if it's false, get the error message
from CheckError()

    my $Valid = $CheckItemObject->CheckEmail(
        Address => 'info@example.com',
    );

=cut

sub CheckEmail {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{Address} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need Address!'
        );
        return;
    }

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # check if it's to do
    return 1 if !$ConfigObject->Get('CheckEmailAddresses');

    # check valid email addresses
    my $RegExp = $ConfigObject->Get('CheckEmailValidAddress');
    if ( $RegExp && $Param{Address} =~ /$RegExp/i ) {
        return 1;
    }
    my $Error = '';

    # Workaround for https://github.com/Perl-Email-Project/Email-Valid/issues/36:
    # remove comment from address when checking.
    $Param{Address} =~ s{ \s* \( [^()]* \) \s* $ }{}smxg;

    # email address syntax check
    if ( !Email::Valid->address( $Param{Address} ) ) {
        $Error = "Invalid syntax";
        $Self->{ErrorType} = 'InvalidSyntax';
    }

    # period (".") may not be used to end the local part,
    # nor may two or more consecutive periods appear
    elsif ( $Param{Address} =~ /(\.\.)|(\.@)/ ) {
        $Error = "Invalid syntax";
        $Self->{ErrorType} = 'InvalidSyntax';
    }

    # mx check
    elsif (
        $ConfigObject->Get('CheckMXRecord')
        && eval { require Net::DNS }
        )
    {

        # get host
        my $Host = $Param{Address};
        $Host =~ s/^.*@(.*)$/$1/;
        $Host =~ s/\s+//g;
        $Host =~ s/(^\[)|(\]$)//g;

        # do dns query
        my $Resolver = Net::DNS::Resolver->new();
        if ($Resolver) {

            # it's no fun to have this hanging in the web interface
            $Resolver->tcp_timeout(3);
            $Resolver->udp_timeout(3);

            # check if we need to use a specific name server
            my $Nameserver = $ConfigObject->Get('CheckMXRecord::Nameserver');
            if ($Nameserver) {
                $Resolver->nameservers($Nameserver);
            }

            # A-record lookup to verify proper DNS setup
            my $Packet = $Resolver->send( $Host, 'A' );
            if ( !$Packet ) {
                $Self->{ErrorType} = 'InvalidDNS';
                $Error = "DNS problem: " . $Resolver->errorstring();
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => $Error,
                );
            }

            else {
                # RFC 5321: first check MX record and fallback to A record if present.
                # mx record lookup
                my @MXRecords = Net::DNS::mx( $Resolver, $Host );

                if ( !@MXRecords ) {

                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                        Priority => 'debug',
                        Message  =>
                            "$Host has no mail exchanger (MX) defined, trying A resource record instead.",
                    );

                    # see if our previous A-record lookup returned a RR
                    if ( scalar $Packet->answer() eq 0 ) {

                        $Self->{ErrorType} = 'InvalidMX';
                        $Error = "$Host has no mail exchanger (MX) or A resource record defined.";

                        $Kernel::OM->Get('Kernel::System::Log')->Log(
                            Priority => 'debug',
                            Message  => $Error,
                        );
                    }
                }
            }
        }
    }
    elsif ( $ConfigObject->Get('CheckMXRecord') ) {

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Can't load Net::DNS, no mx lookups possible",
        );
    }

    # check address
    if ( !$Error ) {

        # check special stuff
        my $RegExp = $ConfigObject->Get('CheckEmailInvalidAddress');
        if ( $RegExp && $Param{Address} =~ /$RegExp/i ) {
            $Self->{Error}     = "invalid $Param{Address} (config)!";
            $Self->{ErrorType} = 'InvalidConfig';
            return;
        }
        return 1;
    }
    else {

        # remember error
        $Self->{Error} = "invalid $Param{Address} ($Error)! ";
        return;
    }
}

=head2 StringClean()

clean a given string

    my $StringRef = $CheckItemObject->StringClean(
        StringRef         => \'String',
        TrimLeft          => 0,  # (optional) default 1
        TrimRight         => 0,  # (optional) default 1
        RemoveAllNewlines => 1,  # (optional) default 0
        RemoveAllTabs     => 1,  # (optional) default 0
        RemoveAllSpaces   => 1,  # (optional) default 0
    );

=cut

sub StringClean {
    my ( $Self, %Param ) = @_;

    if ( !$Param{StringRef} || ref $Param{StringRef} ne 'SCALAR' ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need a scalar reference!'
        );
        return;
    }

    return $Param{StringRef} if !defined ${ $Param{StringRef} };
    return $Param{StringRef} if ${ $Param{StringRef} } eq '';

    # check for invalid utf8 characters and remove invalid strings
    if ( !utf8::valid( ${ $Param{StringRef} } ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Removed string containing invalid utf8: '${ $Param{StringRef} }'!",
        );
        ${ $Param{StringRef} } = '';
        return;
    }

    # set default values
    $Param{TrimLeft}  = defined $Param{TrimLeft}  ? $Param{TrimLeft}  : 1;
    $Param{TrimRight} = defined $Param{TrimRight} ? $Param{TrimRight} : 1;

    my %TrimAction = (
        RemoveAllNewlines => qr{ [\n\r\f] }xms,
        RemoveAllTabs     => qr{ \t       }xms,
        RemoveAllSpaces   => qr{ [ ]      }xms,
        TrimLeft          => qr{ \A \s+   }xms,
        TrimRight         => qr{ \s+ \z   }xms,
    );

    ACTION:
    for my $Action ( sort keys %TrimAction ) {
        next ACTION if !$Param{$Action};

        ${ $Param{StringRef} } =~ s{ $TrimAction{$Action} }{}xmsg;
    }

    return $Param{StringRef};
}

=head2 CreditCardClean()

clean a given string and remove credit card

    my ($StringRef, $Found) = $CheckItemObject->CreditCardClean(
        StringRef => \'String',
    );

=cut

sub CreditCardClean {
    my ( $Self, %Param ) = @_;

    if ( !$Param{StringRef} || ref $Param{StringRef} ne 'SCALAR' ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need a scalar reference!'
        );
        return;
    }

    return ( $Param{StringRef}, 0 ) if ${ $Param{StringRef} } eq '';
    return ( $Param{StringRef}, 0 ) if !defined ${ $Param{StringRef} };

    # strip credit card numbers
    my $Count = 0;
    ${ $Param{StringRef} } =~ s{
        \b(\d{4})(\s|\.|\+|_|-|\\|/)(\d{4})(\s|\.|\+|_|-|\\|/|)(\d{4})(\s|\.|\+|_|-|\\|/)(\d{3,4})\b
    }
    {
        $Count++;
        "$1$2XXXX$4XXXX$6$7";
    }egx;

    return $Param{StringRef}, $Count;
}

1;
