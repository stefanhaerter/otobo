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

package Kernel::System::Console::Command::Admin::Group::Add;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Group'
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Create a new group.');
    $Self->AddOption(
        Name        => 'name',
        Description => "Name of the new group.",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'comment',
        Description => "Comment for the new group.",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Creating a new group...</yellow>\n");

    my $Success = $Kernel::OM->Get('Kernel::System::Group')->GroupAdd(
        UserID  => 1,
        ValidID => 1,
        Comment => $Self->GetOption('comment'),
        Name    => $Self->GetOption('name'),
    );

    # error handling
    if ( !$Success ) {
        $Self->PrintError("Can't create group.\n");
        return $Self->ExitCodeError();
    }

    $Self->Print("<green>Done.</green>\n");

    return $Self->ExitCodeOk();
}

1;
