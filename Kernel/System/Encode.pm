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

package Kernel::System::Encode;

use strict;
use warnings;

use Encode;
use Encode::Locale;
use IO::Interactive qw(is_interactive);

our %ObjectManagerFlags = (
    IsSingleton => 1,
);
our @ObjectDependencies = ();

=head1 NAME

Kernel::System::Encode - character encodings

=head1 DESCRIPTION

This module will use Perl's Encode module (Perl 5.8.0 or higher is required).

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $EncodeObject = $Kernel::OM->Get('Kernel::System::Encode');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # 0=off; 1=on;
    $Self->{Debug} = 0;

    # use "locale" as an arg to encode/decode
    @ARGV = map { decode( locale => $_, 1 ) } @ARGV;    ## no critic qw(Variables::RequireLocalizedPunctuationVars)

    # check if the encodeobject is used from the command line
    # if so, we need to decode @ARGV
    if ( !is_interactive() ) {

        # encode STDOUT and STDERR
        $Self->ConfigureOutputFileHandle( FileHandle => \*STDOUT );
        $Self->ConfigureOutputFileHandle( FileHandle => \*STDERR );
    }
    else {

        if ( is_interactive(*STDOUT) ) {
            binmode STDOUT, ":encoding(console_out)";
        }
        if ( is_interactive(*STDERR) ) {
            binmode STDERR, ":encoding(console_out)";
        }
    }

    return $Self;
}

=head2 Convert()

Convert a string from one charset to another charset.

    my $utf8 = $EncodeObject->Convert(
        Text => $iso_8859_1_string,
        From => 'iso-8859-1',
        To   => 'utf-8',
    );

    my $iso_8859_1 = $EncodeObject->Convert(
        Text => $utf-8_string,
        From => 'utf-8',
        To   => 'iso-8859-1',
    );

There is also a Force => 1 option if you need to force the
already converted string. And Check => 1 if the string result
should be checked to be a valid string (e. g. valid utf-8 string).

=cut

sub Convert {
    my ( $Self, %Param ) = @_;

    # return if no text is given
    return    if !defined $Param{Text};
    return '' if $Param{Text} eq '';

    # check needed stuff
    for (qw(From To)) {
        if ( !defined $Param{$_} ) {
            print STDERR "Need $_!\n";
            return;
        }
    }

    # utf8 cleanup
    for my $Key (qw(From To)) {
        $Param{$Key} = lc $Param{$Key};
        if ( $Param{$Key} eq 'utf8' ) {
            $Param{$Key} = 'utf-8';
        }
    }

    # if no encode is needed
    if ( $Param{From} eq $Param{To} ) {

        # set utf-8 flag
        if ( $Param{To} eq 'utf-8' ) {
            Encode::_utf8_on( $Param{Text} );
        }

        # check if string is valid utf-8
        if ( $Param{Check} && !eval { Encode::is_utf8( $Param{Text}, 1 ) } ) {
            Encode::_utf8_off( $Param{Text} );

            # strip invalid chars / 0 = will put a substitution character in
            # place of a malformed character
            eval { Encode::from_to( $Param{Text}, $Param{From}, $Param{To}, 0 ) };

            # set utf-8 flag
            Encode::_utf8_on( $Param{Text} );

            # return new string
            return $Param{Text};
        }

        # return text
        return $Param{Text};
    }

    # encode is needed
    if ( $Param{Force} ) {
        Encode::_utf8_off( $Param{Text} );
    }

    # this is a workaround for following bug in Encode::HanExtra
    # https://rt.cpan.org/Public/Bug/Display.html?id=71720
    # see also http://bugs.otrs.org/show_bug.cgi?id=10121
    # distributed charsets by Encode::HanExtra
    # http://search.cpan.org/~jhi/perl-5.8.1/ext/Encode/lib/Encode/Supported.pod
    my %AdditionalChineseCharsets = (
        'big5ext'  => 1,
        'big5plus' => 1,
        'cccii'    => 1,
        'euc-tw'   => 1,
        'gb18030'  => 1,
    );

    # check if one of the Encode::HanExtra charsets occurs
    if ( $AdditionalChineseCharsets{ $Param{From} } ) {

        # require module, print error if module was not found
        if ( !eval "require Encode::HanExtra" ) {    ## no critic qw(BuiltinFunctions::ProhibitStringyEval)
            print STDERR
                "Charset '$Param{From}' requires Encode::HanExtra, which is not installed!\n";
        }
    }

    # check if encoding exists
    if ( !Encode::resolve_alias( $Param{From} ) ) {
        my $Fallback = 'iso-8859-1';
        print STDERR "Not supported charset '$Param{From}', fallback to '$Fallback'!\n";
        $Param{From} = $Fallback;
    }

    # set check for "Handling Malformed Data", for more info see "perldoc Encode -> CHECK"

    # 1 = methods will die on error immediately with an error
    my $Check = 1;

    # 0 = will put a substitution character in place of a malformed character
    if ( $Param{Force} ) {
        $Check = 0;
    }

    # convert string
    if ( !eval { Encode::from_to( $Param{Text}, $Param{From}, $Param{To}, $Check ) } ) {

        # truncate text for error messages
        my $TruncatedText = $Param{Text};
        if ( length($TruncatedText) > 65 ) {
            $TruncatedText = substr( $TruncatedText, 0, 65 ) . '[...]';
        }

        print STDERR "Charset encode '$Param{From}' -=> '$Param{To}' ($TruncatedText)"
            . " not supported!\n";

        # strip invalid chars / 0 = will put a substitution character in place of
        # a malformed character
        eval { Encode::from_to( $Param{Text}, $Param{From}, $Param{To}, 0 ) };

        # set utf-8 flag
        if ( $Param{To} eq 'utf-8' ) {
            Encode::_utf8_on( $Param{Text} );
        }

        return $Param{Text};
    }

    # set utf-8 flag
    if ( $Param{To} eq 'utf-8' ) {
        Encode::_utf8_on( $Param{Text} );
    }

    # output debug message
    if ( $Self->{Debug} ) {
        print STDERR "Charset encode '$Param{From}' -=> '$Param{To}' ($Param{Text})!\n";
    }

    return $Param{Text};
}

=head2 Convert2CharsetInternal()

Convert given charset into the internal used charset (utf-8).
Should be used on all I/O interfaces.

    my $String = $EncodeObject->Convert2CharsetInternal(
        Text => $String,
        From => $SourceCharset,
    );

=cut

sub Convert2CharsetInternal {
    my ( $Self, %Param ) = @_;

    return if !defined $Param{Text};

    # check needed stuff
    if ( !defined $Param{From} ) {
        print STDERR "Need From!\n";
        return;
    }

    return $Self->Convert( %Param, To => 'utf-8' );
}

=head2 EncodeInput()

Convert internal used charset (e. g. utf-8) into given charset (utf-8).

Should be used on all I/O interfaces if data is already utf-8 to set the utf-8 stamp.

    $EncodeObject->EncodeInput( \$String );

    $EncodeObject->EncodeInput( \@Array );

=cut

sub EncodeInput {
    my ( $Self, $What ) = @_;

    return if !defined $What;

    if ( ref $What eq 'SCALAR' ) {
        return $What if !defined ${$What};
        Encode::_utf8_on( ${$What} );
        return $What;
    }

    if ( ref $What eq 'ARRAY' ) {

        ROW:
        for my $Row ( @{$What} ) {
            next ROW if !defined $Row;
            Encode::_utf8_on($Row);
        }
        return $What;
    }

    Encode::_utf8_on($What);

    return $What;
}

=head2 EncodeOutput()

Convert utf-8 to a sequence of bytes. All possible characters have
a UTF-8 representation so this function cannot fail.

This should be used in for output of utf-8 chars.

    $EncodeObject->EncodeOutput( \$String );

    $EncodeObject->EncodeOutput( \@Array );

=cut

sub EncodeOutput {
    my ( $Self, $What ) = @_;

    if ( ref $What eq 'SCALAR' ) {
        return $What if !defined ${$What};
        return $What if !Encode::is_utf8( ${$What} );
        ${$What} = Encode::encode_utf8( ${$What} );
        return $What;
    }

    if ( ref $What eq 'ARRAY' ) {

        ROW:
        for my $Row ( @{$What} ) {
            next ROW if !defined $Row;
            next ROW if !Encode::is_utf8( ${$Row} );
            ${$Row} = Encode::encode_utf8( ${$Row} );
        }
        return $What;
    }

    return $What if !Encode::is_utf8( \$What );
    Encode::encode_utf8( \$What );
    return $What;
}

=head2 ConfigureOutputFileHandle()

switch output file handle to utf-8 output.

    $EncodeObject->ConfigureOutputFileHandle( FileHandle => \*STDOUT );

=cut

sub ConfigureOutputFileHandle {
    my ( $Self, %Param ) = @_;

    return if !defined $Param{FileHandle};
    return if ref $Param{FileHandle} ne 'GLOB';

    # http://www.perlmonks.org/?node_id=644786
    # http://bugs.otrs.org/show_bug.cgi?id=12100
    binmode( $Param{FileHandle}, ':utf8' );    ## no critic qw(InputOutput::RequireEncodingWithUTF8Layer)

    return 1;
}

=head2 EncodingIsAsciiSuperset()

Checks if an encoding is a super-set of ASCII, that is, encodes the
codepoints from 0 to 127 the same way as ASCII.

    my $IsSuperset = $EncodeObject->EncodingIsAsciiSuperset(
        Encoding    => 'UTF-8',
    );

=cut

sub EncodingIsAsciiSuperset {
    my ( $Self, %Param ) = @_;
    if ( !defined $Param{Encoding} ) {
        print STDERR "Need Encoding!\n";
        return;
    }
    if ( !defined Encode::find_encoding( $Param{Encoding} ) ) {
        print STDERR "Unsupported Encoding $Param{Encoding}!\n";
        return;
    }
    my $Test = join '', map {chr} 0 .. 127;
    return Encode::encode( $Param{Encoding}, $Test )
        eq Encode::encode( 'ASCII',          $Test );
}

=head2 FindAsciiSupersetEncoding()

From a list of character encodings, returns the first that
is a super-set of ASCII. If none matches, C<ASCII> is returned.

    my $Encoding = $EncodeObject->FindAsciiSupersetEncoding(
        Encodings   => [ 'UTF-16LE', 'UTF-8' ],
    );

=cut

sub FindAsciiSupersetEncoding {
    my ( $Self, %Param ) = @_;
    if ( !defined $Param{Encodings} ) {
        print STDERR "Need Encodings!\n";
        return;
    }
    ENCODING:
    for my $Encoding ( @{ $Param{Encodings} } ) {
        next ENCODING if !$Encoding;
        if ( $Self->EncodingIsAsciiSuperset( Encoding => $Encoding ) ) {
            return $Encoding;
        }
    }
    return 'ASCII';
}

1;
