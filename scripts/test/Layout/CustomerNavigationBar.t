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

# Add test customer user.
my $TestCustomerUserLogin = $HelperObject->TestCustomerUserCreate();
$Self->True(
    $TestCustomerUserLogin // 0,
    "TestCustomerUserCreate - $TestCustomerUserLogin"
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

my $CustomerGroupObject = $Kernel::OM->Get('Kernel::System::CustomerGroup');

my @Tests = (
    {
        Name   => 'CustomerNavigationBar - No customer group support - Empty groups',
        Config => [
            {
                Key   => "CustomerFrontend::Module###Customer$RandomID",
                Value => {
                    Group       => [],
                    GroupRo     => [],
                    Description => 'Customer Test',
                    Title       => '',
                    NavBarName  => $RandomID,
                },
            },
            {
                Key   => "CustomerFrontend::Navigation###Customer$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Group       => [],
                            GroupRo     => [],
                            Description => 'Customer test.',
                            Name        => $RandomID,
                            Link        => "Action=Customer$RandomID;Subaction=Test",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => '',
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
        Name   => 'CustomerNavigationBar - No customer group support - Navigation Group',
        Config => [
            {
                Key   => "CustomerFrontend::Module###Customer$RandomID",
                Value => {
                    Group       => [],
                    GroupRo     => [],
                    Description => 'Customer Test',
                    Title       => '',
                    NavBarName  => $RandomID,
                },
            },
            {
                Key   => "CustomerFrontend::Navigation###Customer$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Group       => [$GroupName],
                            GroupRo     => [],
                            Description => 'Customer test.',
                            Name        => $RandomID,
                            Link        => "Action=Customer$RandomID;Subaction=Test",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => '',
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
        Name   => 'CustomerNavigationBar - No customer group support - Navigation GroupRo',
        Config => [
            {
                Key   => "CustomerFrontend::Module###Customer$RandomID",
                Value => {
                    Group       => [],
                    GroupRo     => [],
                    Description => 'Customer Test',
                    Title       => '',
                    NavBarName  => $RandomID,
                },
            },
            {
                Key   => "CustomerFrontend::Navigation###Customer$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Group       => [],
                            GroupRo     => [$GroupName],
                            Description => 'Customer test.',
                            Name        => $RandomID,
                            Link        => "Action=Customer$RandomID;Subaction=Test",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => '',
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
        Name   => 'CustomerNavigationBar - No customer group support - Module Group',
        Config => [
            {
                Key   => "CustomerFrontend::Module###Customer$RandomID",
                Value => {
                    Group       => [$GroupName],
                    GroupRo     => [],
                    Description => 'Customer Test',
                    Title       => '',
                    NavBarName  => $RandomID,
                },
            },
            {
                Key   => "CustomerFrontend::Navigation###Customer$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Group       => [],
                            GroupRo     => [],
                            Description => 'Customer test.',
                            Name        => $RandomID,
                            Link        => "Action=Customer$RandomID;Subaction=Test",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => '',
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
        Name   => 'CustomerNavigationBar - No customer group support - Module GroupRo',
        Config => [
            {
                Key   => "CustomerFrontend::Module###Customer$RandomID",
                Value => {
                    Group       => [],
                    GroupRo     => [$GroupName],
                    Description => 'Customer Test',
                    Title       => '',
                    NavBarName  => $RandomID,
                },
            },
            {
                Key   => "CustomerFrontend::Navigation###Customer$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Group       => [],
                            GroupRo     => [],
                            Description => 'Customer test.',
                            Name        => $RandomID,
                            Link        => "Action=Customer$RandomID;Subaction=Test",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => '',
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
        Name   => 'CustomerNavigationBar - Customer group support - Empty groups',
        Config => [
            {
                Key   => 'CustomerGroupSupport',
                Value => 1,
            },
            {
                Key   => "CustomerFrontend::Module###Customer$RandomID",
                Value => {
                    Group       => [],
                    GroupRo     => [],
                    Description => 'Customer Test',
                    Title       => '',
                    NavBarName  => $RandomID,
                },
            },
            {
                Key   => "CustomerFrontend::Navigation###Customer$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Group       => [],
                            GroupRo     => [],
                            Description => 'Customer test.',
                            Name        => $RandomID,
                            Link        => "Action=Customer$RandomID;Subaction=Test",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => '',
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
        Name   => 'CustomerNavigationBar - Customer group support - Navigation GroupRo - No access',
        Config => [
            {
                Key   => 'CustomerGroupSupport',
                Value => 1,
            },
            {
                Key   => "CustomerFrontend::Module###Customer$RandomID",
                Value => {
                    Group       => [],
                    GroupRo     => [],
                    Description => 'Customer Test',
                    Title       => '',
                    NavBarName  => $RandomID,
                },
            },
            {
                Key   => "CustomerFrontend::Navigation###Customer$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Test        => 1,
                            Group       => [],
                            GroupRo     => [$GroupName],
                            Description => 'Customer test.',
                            Name        => $RandomID,
                            Link        => "Action=Customer$RandomID;Subaction=Test",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => '',
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
        Name   => 'CustomerNavigationBar - Customer group support - Navigation GroupRo - Access granted',
        Config => [
            {
                Key   => 'CustomerGroupSupport',
                Value => 1,
            },
            {
                Key   => "CustomerFrontend::Module###Customer$RandomID",
                Value => {
                    Group       => [],
                    GroupRo     => [],
                    Description => 'Customer Test',
                    Title       => '',
                    NavBarName  => $RandomID,
                },
            },
            {
                Key   => "CustomerFrontend::Navigation###Customer$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Test        => 1,
                            Group       => [],
                            GroupRo     => [$GroupName],
                            Description => 'Customer test.',
                            Name        => $RandomID,
                            Link        => "Action=Customer$RandomID;Subaction=Test",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => '',
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
        Access => 1,
    },
    {
        Name   => 'CustomerNavigationBar - Customer group support - Module GroupRo - Access granted',
        Config => [
            {
                Key   => 'CustomerGroupSupport',
                Value => 1,
            },
            {
                Key   => "CustomerFrontend::Module###Customer$RandomID",
                Value => {
                    Group       => [],
                    GroupRo     => [],
                    Description => 'Customer Test',
                    Title       => '',
                    NavBarName  => $RandomID,
                },
            },
            {
                Key   => "CustomerFrontend::Navigation###Customer$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Test        => 1,
                            Group       => [],
                            GroupRo     => [$GroupName],
                            Description => 'Customer test.',
                            Name        => $RandomID,
                            Link        => "Action=Customer$RandomID;Subaction=Test",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => '',
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
        Name   => 'CustomerNavigationBar - Customer group support - Navigation Group - No access',
        Config => [
            {
                Key   => 'CustomerGroupSupport',
                Value => 1,
            },
            {
                Key   => "CustomerFrontend::Module###Customer$RandomID",
                Value => {
                    Group       => [],
                    GroupRo     => [],
                    Description => 'Customer Test',
                    Title       => '',
                    NavBarName  => $RandomID,
                },
            },
            {
                Key   => "CustomerFrontend::Navigation###Customer$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Test        => 1,
                            Group       => [$GroupName],
                            GroupRo     => [],
                            Description => 'Customer test.',
                            Name        => $RandomID,
                            Link        => "Action=Customer$RandomID;Subaction=Test",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => '',
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
        Name   => 'CustomerNavigationBar - Customer group support - Navigation Group - Access granted',
        Config => [
            {
                Key   => 'CustomerGroupSupport',
                Value => 1,
            },
            {
                Key   => "CustomerFrontend::Module###Customer$RandomID",
                Value => {
                    Group       => [],
                    GroupRo     => [],
                    Description => 'Customer Test',
                    Title       => '',
                    NavBarName  => $RandomID,
                },
            },
            {
                Key   => "CustomerFrontend::Navigation###Customer$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Test        => 1,
                            Group       => [$GroupName],
                            GroupRo     => [],
                            Description => 'Customer test.',
                            Name        => $RandomID,
                            Link        => "Action=Customer$RandomID;Subaction=Test",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => '',
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
        Name   => 'CustomerNavigationBar - Customer group support - Module Group - No access',
        Config => [
            {
                Key   => 'CustomerGroupSupport',
                Value => 1,
            },
            {
                Key   => "CustomerFrontend::Module###Customer$RandomID",
                Value => {
                    Group       => [$GroupName],
                    GroupRo     => [],
                    Description => 'Customer Test',
                    Title       => '',
                    NavBarName  => $RandomID,
                },
            },
            {
                Key   => "CustomerFrontend::Navigation###Customer$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Test        => 1,
                            Group       => [],
                            GroupRo     => [],
                            Description => 'Customer test.',
                            Name        => $RandomID,
                            Link        => "Action=Customer$RandomID;Subaction=Test",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => '',
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
        Name   => 'CustomerNavigationBar - Customer group support - Module Group - Access granted',
        Config => [
            {
                Key   => 'CustomerGroupSupport',
                Value => 1,
            },
            {
                Key   => "CustomerFrontend::Module###Customer$RandomID",
                Value => {
                    Group       => [$GroupName],
                    GroupRo     => [],
                    Description => 'Customer Test',
                    Title       => '',
                    NavBarName  => $RandomID,
                },
            },
            {
                Key   => "CustomerFrontend::Navigation###Customer$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Test        => 1,
                            Group       => [],
                            GroupRo     => [],
                            Description => 'Customer test.',
                            Name        => $RandomID,
                            Link        => "Action=Customer$RandomID;Subaction=Test",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => '',
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
        Name   => 'CustomerNavigationBar - Customer group support - No frontend registration - No access',
        Config => [
            {
                Key   => 'CustomerGroupSupport',
                Value => 1,
            },
            {
                Key   => "CustomerFrontend::Navigation###Customer$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Test        => 1,
                            Group       => [],
                            GroupRo     => [],
                            Description => 'Customer test.',
                            Name        => $RandomID,
                            Link        => "Action=Customer$RandomID;Subaction=Test",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => '',
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
        Name   => 'CustomerNavigationBar - No customer group support - No frontend registration - No access',
        Config => [
            {
                Key   => "CustomerFrontend::Navigation###Customer$RandomID",
                Value => {
                    '001-Framework' => [
                        {
                            Test        => 1,
                            Group       => [],
                            GroupRo     => [],
                            Description => 'Customer test.',
                            Name        => $RandomID,
                            Link        => "Action=Customer$RandomID;Subaction=Test",
                            LinkOption  => '',
                            NavBar      => $RandomID,
                            Type        => 'Menu',
                            Block       => '',
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
        my $Success = $CustomerGroupObject->GroupMemberAdd(
            %{ $Test->{Group} },
            UID    => $TestCustomerUserLogin,
            UserID => 1,
        );
        $Self->True(
            $Success // 0,
            "GroupMemberAdd - Group ID $Test->{Group}->{GID}"
        );
    }

    my $LayoutObject = Kernel::Output::HTML::Layout->new(
        UserID => $TestCustomerUserLogin,

        # Without these parameters, layout object will complain a lot.
        UserCustomerID => $TestCustomerUserLogin,
        Action         => 'CustomerTicketOverview',
        Subaction      => 'MyTickets',
        UserEmail      => 'customer@example.com',
    );

    my $CustomerNavigationBar = $LayoutObject->CustomerNavigationBar();

    if ( $Test->{Access} ) {
        $Self->True(
            ( $CustomerNavigationBar =~ m{$RandomID}xms ) // 0,
            'CustomerNavigationBar - NavBar found'
        );
    }
    elsif ( !$Test->{Access} ) {
        $Self->False(
            ( $CustomerNavigationBar =~ m{$RandomID}xms ) // 1,
            'CustomerNavigationBar - NavBar not found'
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

    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => 'CustomerGroup',
    );
}

$Self->DoneTesting();
