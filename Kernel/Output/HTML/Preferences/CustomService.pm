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

package Kernel::Output::HTML::Preferences::CustomService;

use strict;
use warnings;

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Cache',
    'Kernel::System::DB',
    'Kernel::System::Service',
    'Kernel::System::Web::Request',
    'Kernel::Config',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    for my $Needed (qw(UserID ConfigItem)) {
        die "Got no $Needed!" if ( !$Self->{$Needed} );
    }

    return $Self;
}

sub Param {
    my ( $Self, %Param ) = @_;

    my @Params;
    my @CustomServiceIDs;

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # check needed param,
    # if no user id is given or Ticket::Service is disabled
    # do not show this box
    if (
        !$Param{UserData}->{UserID}
        || !$ConfigObject->Get('Ticket::Service')
        )
    {
        return ();
    }

    # get all services
    my %ServiceList = $Kernel::OM->Get('Kernel::System::Service')->ServiceList(
        KeepChildren => $ConfigObject->Get('Ticket::Service::KeepChildren') // 0,
        Valid        => 1,
        UserID       => $Self->{UserID},
    );

    # get param object
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    if ( $ParamObject->GetArray( Param => 'ServiceID' ) ) {
        @CustomServiceIDs = $ParamObject->GetArray( Param => 'ServiceID' );
    }
    elsif ( $Param{UserData}->{UserID} && !defined $CustomServiceIDs[0] ) {
        @CustomServiceIDs = $Kernel::OM->Get('Kernel::System::Service')->GetAllCustomServices(
            UserID => $Param{UserData}->{UserID}
        );
    }
    push(
        @Params,
        {
            %Param,
            Option => $Kernel::OM->Get('Kernel::Output::HTML::Layout')->BuildSelection(
                Data        => \%ServiceList,
                Name        => 'ServiceID',
                Class       => 'Modernize',
                Multiple    => 1,
                Size        => 10,
                SelectedID  => \@CustomServiceIDs,
                Sort        => 'AlphanumericValue',
                Translation => 0,
                TreeView    => 1,

            ),
            Name => 'ServiceID',
        },
    );
    return @Params;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # delete old custom services
    $DBObject->Do(
        SQL => "
            DELETE FROM personal_services
            WHERE user_id = ?",
        Bind => [ \$Param{UserData}->{UserID} ],
    );

    # add new custom services
    for my $ServiceID ( @{ $Param{GetParam}->{ServiceID} } ) {
        $DBObject->Do(
            SQL => "
                INSERT INTO personal_services (service_id, user_id)
                VALUES (?, ?)",
            Bind => [ \$ServiceID, \$Param{UserData}->{UserID} ]
        );
    }

    my $CacheKey = 'GetAllCustomServices::' . $Param{UserData}->{UserID};
    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => 'Service',
        Key  => $CacheKey,
    );

    $Self->{Message} = Translatable('Preferences updated successfully!');
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
