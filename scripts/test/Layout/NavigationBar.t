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

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# Unregister all notification modules.
$HelperObject->ConfigSettingChange(
    Valid => 0,
    Key   => 'Frontend::NotifyModule',
);

# Add test user.
my $TestUserLogin = $HelperObject->TestUserCreate(
    Groups => ['users'],
);
$Self->True(
    $TestUserLogin // 0,
    "TestUserCreate - $TestUserLogin"
);

# Get test user ID.
my $TestUserID = $Kernel::OM->Get('Kernel::System::User')->UserLookup(
    UserLogin => $TestUserLogin,
);
$Self->True(
    $TestUserID // 0,
    "UserLookup - $TestUserID"
);

my $RandomID = $HelperObject->GetRandomID();

my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');

# Create test group.
my $GroupName = "group-$RandomID";
my $GroupID   = $GroupObject->GroupAdd(
    Name    => $GroupName,
    ValidID => 1,
    UserID  => 1,
);

my @Tests = (
    {
        Name   => 'NavigationBar - Empty groups',
        Config => [
            {
                Key   => "Frontend::Module###Agent$RandomID",
                Value => {
                    Group       => [],
                    GroupRo     => [],
                    Description => 'Agent Test',
                    Title       => '',
                    NavBarName  => $RandomID,
                },
            },
            {
                Key   => "Frontend::Navigation###Agent$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Group       => [],
                            GroupRo     => [],
                            Description => 'Agent test.',
                            Name        => $RandomID,
                            Link        => "Action=Agent$RandomID",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => 'ItemArea',
                            AccessKey   => '',
                            Prio        => '200',
                        },
                    ],
                },
            },
        ],
        NavBar => $RandomID,
        Access => 1,
    },
    {
        Name   => 'NavigationBar - Additional entry from a test package - Empty groups',
        Config => [
            {
                Key   => "Frontend::Module###Agent$RandomID",
                Value => {
                    Group       => [],
                    GroupRo     => [],
                    Description => 'Agent Test',
                    Title       => '',
                    NavBarName  => $RandomID,
                },
            },
            {
                Key   => "Frontend::Navigation###Agent$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Group       => [],
                            GroupRo     => [],
                            Description => 'Agent test.',
                            Name        => $RandomID,
                            Link        => "Action=Agent$RandomID",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => 'ItemArea',
                            AccessKey   => '',
                            Prio        => '200',
                        },
                    ],
                    '003-TestPackage' => [
                        {
                            Group       => [],
                            GroupRo     => [],
                            Description => 'Agent test.',
                            Name        => 'TestPackage' . $RandomID,
                            Link        => "Action=Agent$RandomID",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => 'ItemArea',
                            AccessKey   => '',
                            Prio        => '200',
                        },
                    ],
                },
            },
        ],
        NavBar => 'TestPackage' . $RandomID,
        Access => 1,
    },
    {
        Name   => 'NavigationBar - Navigation GroupRo - No access',
        Config => [
            {
                Key   => "Frontend::Module###Agent$RandomID",
                Value => {
                    Group       => [],
                    GroupRo     => [],
                    Description => 'Agent Test',
                    Title       => '',
                    NavBarName  => $RandomID,
                },
            },
            {
                Key   => "Frontend::Navigation###Agent$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Group       => [],
                            GroupRo     => [$GroupName],
                            Description => 'Agent test.',
                            Name        => $RandomID,
                            Link        => "Action=Agent$RandomID",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => 'ItemArea',
                            AccessKey   => '',
                            Prio        => '200',
                        },
                    ],
                },
            },
        ],
        NavBar => $RandomID,
        Access => 0,
    },
    {
        Name   => 'NavigationBar - Navigation GroupRo - Access granted',
        Config => [
            {
                Key   => "Frontend::Module###Agent$RandomID",
                Value => {
                    Group       => [],
                    GroupRo     => [],
                    Description => 'Agent Test',
                    Title       => '',
                    NavBarName  => $RandomID,
                },
            },
            {
                Key   => "Frontend::Navigation###Agent$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Group       => [],
                            GroupRo     => [$GroupName],
                            Description => 'Agent test.',
                            Name        => $RandomID,
                            Link        => "Action=Agent$RandomID",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => 'ItemArea',
                            AccessKey   => '',
                            Prio        => '200',
                        },
                    ],
                },
            },
        ],
        Group => {
            GID        => $GroupID,
            Permission => {
                ro => 1,
            },
        },
        NavBar => $RandomID,
        Access => 1,
    },
    {
        Name   => 'NavigationBar - Module GroupRo - Access granted',
        Config => [
            {
                Key   => "Frontend::Module###Agent$RandomID",
                Value => {
                    Group       => [],
                    GroupRo     => [$GroupName],
                    Description => 'Agent Test',
                    Title       => '',
                    NavBarName  => $RandomID,
                },
            },
            {
                Key   => "Frontend::Navigation###Agent$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Group       => [],
                            GroupRo     => [],
                            Description => 'Agent test.',
                            Name        => $RandomID,
                            Link        => "Action=Agent$RandomID",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => 'ItemArea',
                            AccessKey   => '',
                            Prio        => '200',
                        },
                    ],
                },
            },
        ],
        NavBar => $RandomID,
        Access => 1,
    },
    {
        Name   => 'NavigationBar - Navigation Group - No access',
        Config => [
            {
                Key   => "Frontend::Module###Agent$RandomID",
                Value => {
                    Group       => [],
                    GroupRo     => [],
                    Description => 'Agent Test',
                    Title       => '',
                    NavBarName  => $RandomID,
                },
            },
            {
                Key   => "Frontend::Navigation###Agent$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Group       => [$GroupName],
                            GroupRo     => [],
                            Description => 'Agent test.',
                            Name        => $RandomID,
                            Link        => "Action=Agent$RandomID",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => 'ItemArea',
                            AccessKey   => '',
                            Prio        => '200',
                        },
                    ],
                },
            },
        ],
        NavBar => $RandomID,
        Access => 0,
    },
    {
        Name   => 'NavigationBar - Navigation Group - Access granted',
        Config => [
            {
                Key   => "Frontend::Module###Agent$RandomID",
                Value => {
                    Group       => [],
                    GroupRo     => [],
                    Description => 'Agent Test',
                    Title       => '',
                    NavBarName  => $RandomID,
                },
            },
            {
                Key   => "Frontend::Navigation###Agent$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Group       => [$GroupName],
                            GroupRo     => [],
                            Description => 'Agent test.',
                            Name        => $RandomID,
                            Link        => "Action=Agent$RandomID",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => 'ItemArea',
                            AccessKey   => '',
                            Prio        => '200',
                        },
                    ],
                },
            },
        ],
        Group => {
            GID        => $GroupID,
            Permission => {
                rw => 1,
            },
        },
        NavBar => $RandomID,
        Access => 1,
    },
    {
        Name   => 'NavigationBar - Module Group - No access',
        Config => [
            {
                Key   => "Frontend::Module###Agent$RandomID",
                Value => {
                    Group       => [$GroupName],
                    GroupRo     => [],
                    Description => 'Agent Test',
                    Title       => '',
                    NavBarName  => $RandomID,
                },
            },
            {
                Key   => "Frontend::Navigation###Agent$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Group       => [],
                            GroupRo     => [],
                            Description => 'Agent test.',
                            Name        => $RandomID,
                            Link        => "Action=Agent$RandomID",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => 'ItemArea',
                            AccessKey   => '',
                            Prio        => '200',
                        },
                    ],
                },
            },
        ],
        Group => {
            GID        => $GroupID,
            Permission => {
                ro        => 1,
                move_into => 0,
                create    => 0,
                owner     => 0,
                priority  => 0,
                rw        => 0,
            },
        },
        NavBar => $RandomID,
        Access => 0,
    },
    {
        Name   => 'NavigationBar - Module Group - No access',
        Config => [
            {
                Key   => "Frontend::Module###Agent$RandomID",
                Value => {
                    Group       => [$GroupName],
                    GroupRo     => [],
                    Description => 'Agent Test',
                    Title       => '',
                    NavBarName  => $RandomID,
                },
            },
            {
                Key   => "Frontend::Navigation###Agent$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Group       => [],
                            GroupRo     => [],
                            Description => 'Agent test.',
                            Name        => $RandomID,
                            Link        => "Action=Agent$RandomID",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => 'ItemArea',
                            AccessKey   => '',
                            Prio        => '200',
                        },
                    ],
                },
            },
        ],
        Group => {
            GID        => $GroupID,
            Permission => {
                ro        => 1,
                move_into => 0,
                create    => 0,
                owner     => 0,
                priority  => 0,
                rw        => 0,
            },
        },
        NavBar => $RandomID,
        Access => 0,
    },
    {
        Name   => 'NavigationBar - Module Group - Access granted',
        Config => [
            {
                Key   => "Frontend::Module###Agent$RandomID",
                Value => {
                    Group       => [$GroupName],
                    GroupRo     => [],
                    Description => 'Agent Test',
                    Title       => '',
                    NavBarName  => $RandomID,
                },
            },
            {
                Key   => "Frontend::Navigation###Agent$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Group       => [],
                            GroupRo     => [],
                            Description => 'Agent test.',
                            Name        => $RandomID,
                            Link        => "Action=Agent$RandomID",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => 'ItemArea',
                            AccessKey   => '',
                            Prio        => '200',
                        },
                    ],
                },
            },
        ],
        Group => {
            GID        => $GroupID,
            Permission => {
                rw => 1,
            },
        },
        NavBar => $RandomID,
        Access => 1,
    },
    {
        Name   => 'NavigationBar - No frontend registration - No access',
        Config => [
            {
                Key   => "Frontend::Navigation###Agent$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Group       => [$GroupName],
                            GroupRo     => [],
                            Description => 'Agent test.',
                            Name        => $RandomID,
                            Link        => "Action=Agent$RandomID",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => 'ItemArea',
                            AccessKey   => '',
                            Prio        => '200',
                        },
                    ],
                },
            },
        ],
        NavBar => $RandomID,
        Access => 0,
    },
);

for my $Test (@Tests) {
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    for my $Config ( @{ $Test->{Config} || [] } ) {
        my $Success = $ConfigObject->Set(
            %{$Config},
        );
        $Self->True(
            $Success // 0,
            'Set - Set custom config'
        );
    }

    if ( $Test->{Group} ) {
        my $Success = $GroupObject->PermissionGroupUserAdd(
            %{ $Test->{Group} },
            UID    => $TestUserID,
            UserID => 1,
        );
        $Self->True(
            $Success // 0,
            "PermissionGroupUserAdd - Group ID $Test->{Group}->{GID}"
        );
    }

    my $LayoutObject = Kernel::Output::HTML::Layout->new(
        UserID => $TestUserID,
    );

    my $NavigationBar = $LayoutObject->NavigationBar();

    if ( $Test->{Access} ) {
        $Self->True(
            ( $NavigationBar =~ m{nav-$RandomID}xms ) // 0,
            'NavigationBar - NavBar found'
        );
    }
    elsif ( !$Test->{Access} ) {
        $Self->False(
            ( $NavigationBar =~ m{nav-$RandomID}xms ) // 1,
            'NavigationBar - NavBar not found'
        );
    }

    for my $ConfigKey ( map { $_->{Key} } @{ $Test->{Config} || [] } ) {
        my $Success = $ConfigObject->Set(
            Key   => $ConfigKey,
            Value => undef,
        );
        $Self->True(
            $Success // 0,
            'Set - Cleared custom config'
        );
    }
}

$Self->DoneTesting();
