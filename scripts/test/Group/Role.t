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

use strict;
use warnings;
use utf8;

# Set up the test driver $Self when we are running as a standalone script.
use Kernel::System::UnitTest::RegisterDriver;

use vars (qw($Self));

# get group object
my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');

#
# Role tests
#

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $GroupNameRandom  = $Helper->GetRandomID();
my %RoleIDByRoleName = (
    'test-role-' . $GroupNameRandom . '-1' => undef,
    'test-role-' . $GroupNameRandom . '-2' => undef,
    'test-role-' . $GroupNameRandom . '-3' => undef,
);

# try to add roles
for my $RoleName ( sort keys %RoleIDByRoleName ) {
    my $RoleID = $GroupObject->RoleAdd(
        Name    => $RoleName,
        ValidID => 1,
        UserID  => 1,
    );

    $Self->True(
        $RoleID,
        'RoleAdd() for new role ' . $RoleName,
    );

    if ($RoleID) {
        $RoleIDByRoleName{$RoleName} = $RoleID;
    }
}

# try to add already added roles
for my $RoleName ( sort keys %RoleIDByRoleName ) {
    my $RoleID = $GroupObject->RoleAdd(
        Name    => $RoleName,
        ValidID => 1,
        UserID  => 1,
    );

    $Self->False(
        $RoleID,
        'RoleAdd() for already existing role ' . $RoleName,
    );
}

# try to fetch data of existing roles
for my $RoleName ( sort keys %RoleIDByRoleName ) {
    my $RoleID = $RoleIDByRoleName{$RoleName};
    my %Role   = $GroupObject->RoleGet( ID => $RoleID );

    $Self->Is(
        $Role{Name},
        $RoleName,
        'RoleGet() for role ' . $RoleName,
    );
}

# look up existing roles
for my $RoleName ( sort keys %RoleIDByRoleName ) {
    my $RoleID = $RoleIDByRoleName{$RoleName};

    my $FetchedRoleID = $GroupObject->RoleLookup( Role => $RoleName );
    $Self->Is(
        $FetchedRoleID,
        $RoleID,
        'RoleLookup() for role name ' . $RoleName,
    );

    my $FetchedRoleName = $GroupObject->RoleLookup( RoleID => $RoleID );
    $Self->Is(
        $FetchedRoleName,
        $RoleName,
        'RoleLookup() for role ID ' . $RoleID,
    );
}

# list roles
my %Roles = $GroupObject->RoleList();
for my $RoleName ( sort keys %RoleIDByRoleName ) {
    my $RoleID = $RoleIDByRoleName{$RoleName};

    $Self->True(
        exists $Roles{$RoleID} && $Roles{$RoleID} eq $RoleName,
        'RoleList() contains role ' . $RoleName . ' with ID ' . $RoleID,
    );
}

# role data list
my %RoleDataList = $GroupObject->RoleDataList();
for my $RoleName ( sort keys %RoleIDByRoleName ) {
    my $RoleID = $RoleIDByRoleName{$RoleName};

    $Self->True(
        exists $RoleDataList{$RoleID} && $RoleDataList{$RoleID}->{Name} eq $RoleName,
        'RoleDataList() contains role ' . $RoleName . ' with ID ' . $RoleID,
    );
}

# change name of a single role
my $RoleNameToChange = 'test-role-' . $GroupNameRandom . '-1';
my $ChangedRoleName  = $RoleNameToChange . '-changed';
my $RoleIDToChange   = $RoleIDByRoleName{$RoleNameToChange};

my $RoleUpdateResult = $GroupObject->RoleUpdate(
    ID      => $RoleIDToChange,
    Name    => $ChangedRoleName,
    ValidID => 1,
    UserID  => 1,
);

$Self->True(
    $RoleUpdateResult,
    'RoleUpdate() for changing name of role ' . $RoleNameToChange . ' to ' . $ChangedRoleName,
);

$RoleIDByRoleName{$ChangedRoleName} = $RoleIDToChange;
delete $RoleIDByRoleName{$RoleNameToChange};

# try to add role with previous name
my $RoleID1 = $GroupObject->RoleAdd(
    Name    => $RoleNameToChange,
    ValidID => 1,
    UserID  => 1,
);

$Self->True(
    $RoleID1,
    'RoleAdd() for new role ' . $RoleNameToChange,
);

if ($RoleID1) {
    $RoleIDByRoleName{$RoleNameToChange} = $RoleID1;
}

# try to add role with changed name
$RoleID1 = $GroupObject->RoleAdd(
    Name    => $ChangedRoleName,
    ValidID => 1,
    UserID  => 1,
);

$Self->False(
    $RoleID1,
    'RoleAdd() add role with existing name ' . $ChangedRoleName,
);

my $RoleName2 = $ChangedRoleName . 'update';
my $RoleID2   = $GroupObject->RoleAdd(
    Name    => $RoleName2,
    ValidID => 1,
    UserID  => 1,
);

$Self->True(
    $RoleID2,
    'RoleAdd() add the second test role ' . $RoleName2,
);

# try to update role with existing name
my $RoleUpdateWrong = $GroupObject->RoleUpdate(
    ID      => $RoleID2,
    Name    => $ChangedRoleName,
    ValidID => 2,
    UserID  => 1,
);

$Self->False(
    $RoleUpdateWrong,
    'RoleUpdate() update role with existing name ' . $ChangedRoleName,
);

# cleanup is done by RestoreDatabase

$Self->DoneTesting();
