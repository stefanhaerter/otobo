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

# get needed objects
my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

#
# Group tests
#
my $GroupNameRandomPartBase = $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch();
my %GroupIDByGroupName      = (
    'test-group-' . $GroupNameRandomPartBase . '-1' => undef,
    'test-group-' . $GroupNameRandomPartBase . '-2' => undef,
    'test-group-' . $GroupNameRandomPartBase . '-3' => undef,
);

# try to add groups
for my $GroupName ( sort keys %GroupIDByGroupName ) {
    my $GroupID = $GroupObject->GroupAdd(
        Name    => $GroupName,
        ValidID => 1,
        UserID  => 1,
    );

    $Self->True(
        $GroupID,
        'GroupAdd() for new group ' . $GroupName,
    );

    if ($GroupID) {
        $GroupIDByGroupName{$GroupName} = $GroupID;
    }
}

# try to add already added groups
for my $GroupName ( sort keys %GroupIDByGroupName ) {
    my $GroupID = $GroupObject->GroupAdd(
        Name    => $GroupName,
        ValidID => 1,
        UserID  => 1,
    );

    $Self->False(
        $GroupID,
        'GroupAdd() for already existing group ' . $GroupName,
    );
}

# try to fetch data of existing groups
for my $GroupName ( sort keys %GroupIDByGroupName ) {
    my $GroupID = $GroupIDByGroupName{$GroupName};
    my %Group   = $GroupObject->GroupGet( ID => $GroupID );

    $Self->Is(
        $Group{Name},
        $GroupName,
        'GroupGet() for group ' . $GroupName,
    );
}

# look up existing groups
for my $GroupName ( sort keys %GroupIDByGroupName ) {
    my $GroupID = $GroupIDByGroupName{$GroupName};

    my $FetchedGroupID = $GroupObject->GroupLookup( Group => $GroupName );
    $Self->Is(
        $FetchedGroupID,
        $GroupID,
        'GroupLookup() for group name ' . $GroupName,
    );

    my $FetchedGroupName = $GroupObject->GroupLookup( GroupID => $GroupID );
    $Self->Is(
        $FetchedGroupName,
        $GroupName,
        'GroupLookup() for group ID ' . $GroupID,
    );
}

# list groups
my %Groups = $GroupObject->GroupList();
for my $GroupName ( sort keys %GroupIDByGroupName ) {
    my $GroupID = $GroupIDByGroupName{$GroupName};

    $Self->True(
        exists $Groups{$GroupID} && $Groups{$GroupID} eq $GroupName,
        'GroupList() contains the group ' . $GroupName . ' with ID ' . $GroupID,
    );
}

# group data list
my %GroupDataList = $GroupObject->GroupDataList();
for my $GroupName ( sort keys %GroupIDByGroupName ) {
    my $GroupID = $GroupIDByGroupName{$GroupName};

    $Self->True(
        exists $GroupDataList{$GroupID} && $GroupDataList{$GroupID}->{Name} eq $GroupName,
        'GroupDataList() contains the group ' . $GroupName . ' with ID ' . $GroupID,
    );
}

# change name of a single group
my $GroupNameToChange = 'test-group-' . $GroupNameRandomPartBase . '-1';
my $ChangedGroupName  = $GroupNameToChange . '-changed';
my $GroupIDToChange   = $GroupIDByGroupName{$GroupNameToChange};

my $GroupUpdateResult = $GroupObject->GroupUpdate(
    ID      => $GroupIDToChange,
    Name    => $ChangedGroupName,
    ValidID => 1,
    UserID  => 1,
);

$Self->True(
    $GroupUpdateResult,
    'GroupUpdate() for changing name of group ' . $GroupNameToChange . ' to ' . $ChangedGroupName,
);

$GroupIDByGroupName{$ChangedGroupName} = $GroupIDToChange;
delete $GroupIDByGroupName{$GroupNameToChange};

# try to add group with previous name
my $GroupID = $GroupObject->GroupAdd(
    Name    => $GroupNameToChange,
    ValidID => 1,
    UserID  => 1,
);

$Self->True(
    $GroupID,
    'GroupAdd() for new group ' . $GroupNameToChange,
);

if ($GroupID) {
    $GroupIDByGroupName{$GroupNameToChange} = $GroupID;
}

# try to add group with changed name
$GroupID = $GroupObject->GroupAdd(
    Name    => $ChangedGroupName,
    ValidID => 1,
    UserID  => 1,
);

$Self->False(
    $GroupID,
    'GroupAdd() for new group ' . $ChangedGroupName,
);

# set created groups to invalid
GROUPNAME:
for my $GroupName ( sort keys %GroupIDByGroupName ) {
    next GROUPNAME if !$GroupIDByGroupName{$GroupName};

    my $GroupUpdate = $GroupObject->GroupUpdate(
        ID      => $GroupIDByGroupName{$GroupName},
        Name    => $GroupName,
        ValidID => 2,
        UserID  => 1,
    );

    $Self->True(
        $GroupUpdate,
        'GroupUpdate() to set group ' . $GroupName . ' to invalid',
    );
}

# list valid groups
%Groups = $GroupObject->GroupList( Valid => 1 );
for my $GroupName ( sort keys %GroupIDByGroupName ) {
    my $GroupID = $GroupIDByGroupName{$GroupName};

    $Self->False(
        exists $Groups{$GroupID},
        'GroupList() does not contain the group ' . $GroupName . ' with ID ' . $GroupID,
    );
}

# list all groups
%Groups = $GroupObject->GroupList( Valid => 0 );
for my $GroupName ( sort keys %GroupIDByGroupName ) {
    my $GroupID = $GroupIDByGroupName{$GroupName};

    $Self->True(
        exists $Groups{$GroupID} && $Groups{$GroupID} eq $GroupName,
        'GroupList() contains the group ' . $GroupName . ' with ID ' . $GroupID,
    );
}

# Cleanup is done by RestoreDatabase.

$Self->DoneTesting();
