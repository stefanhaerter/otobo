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

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $Helper        = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject  = $Kernel::OM->Get('Kernel::System::Ticket');
my $ServiceObject = $Kernel::OM->Get('Kernel::System::Service');
my $TypeObject    = $Kernel::OM->Get('Kernel::System::Type');

my $TestUserLogin = $Helper->TestCustomerUserCreate();

my $Random = $Helper->GetRandomNumber();

my $TypeID1 = $TypeObject->TypeAdd(
    Name    => 'TestType1' . $Random,
    ValidID => 1,
    UserID  => 1,
);
$Self->True(
    $TypeID1,
    'Type 1 created.',
);

my $TypeID2 = $TypeObject->TypeAdd(
    Name    => 'TestType2' . $Random,
    ValidID => 1,
    UserID  => 1,
);
$Self->True(
    $TypeID2,
    'Type 2 created.',
);

my $ServiceID1 = $ServiceObject->ServiceAdd(
    Name    => 'TestService1' . $Random,
    ValidID => 1,
    UserID  => 1,
);
$Self->True(
    $ServiceID1,
    'Service 1 created.',
);
my $ServiceID2 = $ServiceObject->ServiceAdd(
    Name    => 'TestService2' . $Random,
    ValidID => 1,
    UserID  => 1,
);
$Self->True(
    $ServiceID2,
    'Service 2 created.',
);

my $QueueID = $Kernel::OM->Get('Kernel::System::Queue')->QueueLookup( Queue => 'Raw' );

my $TicketID = $TicketObject->TicketCreate(
    Title        => 'Test ticket title ' . $Random,
    QueueID      => $QueueID,
    Lock         => 'unlock',
    Priority     => '3 normal',
    State        => 'new',
    CustomerUser => $TestUserLogin,
    OwnerID      => 1,
    UserID       => 1,
);

$Self->True(
    $TicketID,
    'Ticket created.',
);

my @Tests = (
    {
        Name   => 'TicketServiceList() - Missing UserID or CustomerUserID',
        Params => {
            TicketID => $TicketID,
        },
        ExpectedResult => 0,
    },
    {
        Name   => 'TicketServiceList() - Missing TicketID or QueueID',
        Params => {
            UserID => 1,
        },
        ExpectedResult => 0,
    },
    {
        Name   => 'TicketServiceList() - UserID and TicketID',
        Params => {
            TicketID => $TicketID,
            UserID   => 1,
        },
        ExpectedResult => {
            "$ServiceID1" => 'TestService1' . $Random,
            "$ServiceID2" => 'TestService2' . $Random,

            # There might be other services as well...
        },
    },
    {
        Name   => 'TicketServiceList() - UserID and QueueID',
        Params => {
            QueueID => $QueueID,
            UserID  => 1,
        },
        ExpectedResult => {
            "$ServiceID1" => 'TestService1' . $Random,
            "$ServiceID2" => 'TestService2' . $Random,

            # There might be other services as well...
        },
    },
    {
        Name   => 'TicketServiceList() - CustomerUserID and QueueID',
        Params => {
            QueueID        => $QueueID,
            CustomerUserID => $TestUserLogin,
        },
        ExpectedResult => {

            # There might be other services as well...
        },
    },
    {
        Name   => 'TicketServiceList() - CustomerUserID and TicketID',
        Params => {
            TicketID       => $TicketID,
            CustomerUserID => $TestUserLogin,
        },
        ExpectedResult => {

            # There might be other services as well...
        },
    },
);

for my $Test (@Tests) {

    my %List = $TicketObject->TicketServiceList(
        %{ $Test->{Params} },
    );

    if ( $Test->{ExpectedResult} ) {

        # if ($Test->{Params}->{UserID}) {
        # Remove all other services that are not created in this test.
        my @Filter = grep { $_ == $ServiceID1 || $_ == $ServiceID2 } keys %List;
        my %Temp;
        @Temp{@Filter} = @List{@Filter};
        %List = %Temp;

        # }
        $Self->IsDeeply(
            \%List,
            $Test->{ExpectedResult},
            "$Test->{Name} - Check if result matches expected value.",
        );
    }
    else {
        $Self->False(
            %List ? 1 : 0,
            "$Test->{Name} - CCCheck if result matches expected value.",
        );
    }
}

$ServiceObject->CustomerUserServiceMemberAdd(
    CustomerUserLogin => $TestUserLogin,
    ServiceID         => $ServiceID1,
    Active            => 1,
    UserID            => 1,
);

@Tests = (
    {
        Name   => 'TicketServiceList() - UserID and TicketID',
        Params => {
            TicketID => $TicketID,
            UserID   => 1,
        },
        ExpectedResult => {
            "$ServiceID1" => 'TestService1' . $Random,
            "$ServiceID2" => 'TestService2' . $Random,

            # There might be other services as well...
        },
    },
    {
        Name   => 'TicketServiceList() - UserID and QueueID',
        Params => {
            QueueID => $QueueID,
            UserID  => 1,
        },
        ExpectedResult => {
            "$ServiceID1" => 'TestService1' . $Random,
            "$ServiceID2" => 'TestService2' . $Random,

            # There might be other services as well...
        },
    },
    {
        Name   => 'TicketServiceList() - CustomerUserID and QueueID',
        Params => {
            QueueID        => $QueueID,
            CustomerUserID => $TestUserLogin,
        },
        ExpectedResult => {
            "$ServiceID1" => 'TestService1' . $Random,

            # There might be other services as well...
        },
    },
    {
        Name   => 'TicketServiceList() - CustomerUserID and TicketID',
        Params => {
            TicketID       => $TicketID,
            CustomerUserID => $TestUserLogin,
        },
        ExpectedResult => {
            "$ServiceID1" => 'TestService1' . $Random,

            # There might be other services as well...
        },
    },
);

for my $Test (@Tests) {

    my %List = $TicketObject->TicketServiceList(
        %{ $Test->{Params} },
    );

    if ( $Test->{ExpectedResult} ) {

        # Remove all other services that are not created in this test.
        my @Filter = grep { $_ == $ServiceID1 || $_ == $ServiceID2 } keys %List;
        my %Temp;
        @Temp{@Filter} = @List{@Filter};
        %List = %Temp;

        $Self->IsDeeply(
            \%List,
            $Test->{ExpectedResult},
            "$Test->{Name} - Check if result matches expected value.",
        );
    }
    else {
        $Self->False(
            %List ? 1 : 0,
            "$Test->{Name} - CCCheck if result matches expected value.",
        );
    }
}

# Cleanup is done by RestoreDatabase.

$Self->DoneTesting();
