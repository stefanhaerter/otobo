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

package Kernel::Output::HTML::Preferences::Avatar;

use strict;
use warnings;

use Digest::MD5 qw(md5_hex);

our @ObjectDependencies = (
    'Kernel::System::Web::Request',
    'Kernel::Config',
    'Kernel::System::AuthSession',
    'Kernel::System::Encode',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    for my $Needed (qw(UserID UserObject ConfigItem)) {
        die "Got no $Needed!" if ( !$Self->{$Needed} );
    }

    return $Self;
}

sub Param {
    my ( $Self, %Param ) = @_;

    my $AvatarEngine = $Kernel::OM->Get('Kernel::Config')->Get('Frontend::AvatarEngine');
    my $Return       = {
        AvatarEngine => $AvatarEngine,
    };

    if ( $AvatarEngine eq 'Gravatar' && $Self->{UserEmail} ) {
        $Kernel::OM->Get('Kernel::System::Encode')->EncodeOutput( \$Self->{UserEmail} );
        $Return->{Avatar} = '//www.gravatar.com/avatar/' . md5_hex( lc $Self->{UserEmail} ) . '?s=45&d=mp';
    }

    return $Return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    return 1;
}

sub Error {
    my ( $Self, %Param ) = @_;

    return $Self->{Error} || '';
}

sub Message {
    my ( $Self, %Param ) = @_;

    return $Self->{Message} || '';
}

1;
