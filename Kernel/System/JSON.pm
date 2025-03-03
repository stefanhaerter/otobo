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

package Kernel::System::JSON;

use strict;
use warnings;

use JSON;

our @ObjectDependencies = (
    'Kernel::System::Log',
);

=head1 NAME

Kernel::System::JSON - the JSON wrapper lib

=head1 DESCRIPTION

Functions for encoding perl data structures to JSON.

=head1 PUBLIC INTERFACE

=head2 new()

create a JSON object. Do not use it directly, instead use:

    my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 Encode()

Encode a perl data structure to a JSON string.

    my $JSONString = $JSONObject->Encode(
        Data     => $Data,
        SortKeys => 1,          # (optional) (0|1) default 0, to sort the keys of the json data
        Pretty => 1,            # (optional) (0|1) default 0, to pretty print
    );

=cut

sub Encode {
    my ( $Self, %Param ) = @_;

    # check for needed data
    if ( !defined $Param{Data} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need Data!',
        );
        return;
    }

    # create json object
    my $JSONObject = JSON->new();

    $JSONObject->allow_nonref(1);

    # sort the keys of the JSON data
    if ( $Param{SortKeys} ) {
        $JSONObject->canonical(1);
    }

    # pretty print - can be useful for debugging purposes
    if ( $Param{Pretty} ) {
        $JSONObject->pretty(1);
    }

    # get JSON-encoded presentation of perl structure
    my $JSONEncoded = $JSONObject->encode( $Param{Data} ) || '""';

    # Special handling for unicode line terminators (\u2028 and \u2029),
    # they are allowed in JSON but not in JavaScript
    # see: http://timelessrepo.com/json-isnt-a-javascript-subset
    #
    # Should be fixed in JSON module, but bug report is still open
    # see: https://rt.cpan.org/Public/Bug/Display.html?id=75755
    #
    # Therefore must be encoded manually
    $JSONEncoded =~ s/\x{2028}/\\u2028/xmsg;
    $JSONEncoded =~ s/\x{2029}/\\u2029/xmsg;

    return $JSONEncoded;
}

=head2 Decode()

Decode a JSON string to a perl data structure.

    my $PerlStructureScalar = $JSONObject->Decode(
        Data => $JSONString,
    );

=cut

sub Decode {
    my ( $Self, %Param ) = @_;

    # check for needed data
    return if !defined $Param{Data};

    # create json object
    my $JSONObject = JSON->new();

    $JSONObject->allow_nonref(1);

    # decode JSON encoded to perl structure
    my $Scalar;

    # use eval here, as JSON::XS->decode() dies when providing a malformed JSON string
    if ( !eval { $Scalar = $JSONObject->decode( $Param{Data} ) } ) {

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Decoding the JSON string failed: ' . $@,
        );

        return;
    }

    # sanitize leftover boolean objects
    $Scalar = $Self->_BooleansProcess(
        JSON => $Scalar,
    );

    return $Scalar;
}

=head2 True()

returns a constant that can be mapped to a boolean true value
in JSON rather than a string with "true".

    my $TrueConstant = $JSONObject->True();

    my $TrueJS = $JSONObject->Encode(
        Data => $TrueConstant,
    );

This will return the string 'true'.
If you pass the perl string 'true' to JSON, it will return '"true"'
as a JavaScript string instead.

=cut

sub True {

    # Use constant instead of JSON::false() as this can cause nasty problems with JSON::XS on some platforms.
    # (encountered object '1', but neither allow_blessed, convert_blessed nor allow_tags settings are enabled)
    return \1;
}

=head2 False()

like C<True()>, but for a false boolean value.

=cut

sub False {

    # Use constant instead of JSON::false() as this can cause nasty problems with JSON::XS on some platforms.
    # (encountered object '0', but neither allow_blessed, convert_blessed nor allow_tags settings are enabled)
    return \0;
}

=begin Internal:

=cut

=head2 _BooleansProcess()

decode boolean values leftover from JSON decoder to simple scalar values

    my $ProcessedJSON = $JSONObject->_BooleansProcess(
        JSON => $JSONData,
    );

=cut

sub _BooleansProcess {
    my ( $Self, %Param ) = @_;

    # convert scalars if needed
    if ( JSON::is_bool( $Param{JSON} ) ) {
        $Param{JSON} = ( $Param{JSON} ? 1 : 0 );
    }

    # recurse into arrays
    elsif ( ref $Param{JSON} eq 'ARRAY' ) {

        for my $Value ( @{ $Param{JSON} } ) {
            $Value = $Self->_BooleansProcess(
                JSON => $Value,
            );
        }
    }

    # recurse into hashes
    elsif ( ref $Param{JSON} eq 'HASH' ) {

        for my $Value ( values %{ $Param{JSON} } ) {
            $Value = $Self->_BooleansProcess(
                JSON => $Value,
            );
        }
    }

    return $Param{JSON};
}

=end Internal:

=cut

1;
