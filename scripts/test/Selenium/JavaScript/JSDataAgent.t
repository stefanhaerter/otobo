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

# OTOBO modules
use Kernel::System::UnitTest::Selenium;
my $Selenium = Kernel::System::UnitTest::Selenium->new( LogExecuteCommandActive => 1 );

$Selenium->RunTest(
    sub {

        # get needed objects
        my $Helper       = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

        my @Tests = (
            {
                Key           => 'UserLanguage',
                ExpectedValue => 'en',
                Environment   => 1,
            },
            {
                Key           => 'Action',
                ExpectedValue => 'AgentTicketPhone',
                Environment   => 1,
            },
            {
                Key           => 'Subaction',
                ExpectedValue => undef,
                Environment   => 1,
            },
            {
                Key           => 'Frontend::WebPath',
                JSKey         => 'WebPath',
                ExpectedValue => $ConfigObject->Get('Frontend::WebPath'),
                Environment   => 1,
            },
            {
                Key           => 'CustomerPanelSessionName',
                ExpectedValue => 'OTOBOUTValue',
            },
            {
                Key           => 'CheckEmailAddresses',
                ExpectedValue => '3',
            },
            {
                Key           => 'Frontend::RichText',
                JSKey         => 'RichTextSet',
                ExpectedValue => '5',
            },
            {
                Key           => 'Frontend::MenuDragDropEnabled',
                JSKey         => 'MenuDragDropEnabled',
                ExpectedValue => '7',
            },
            {
                Key           => 'OpenMainMenuOnHover',
                JSKey         => 'OpenMainMenuOnHover',
                ExpectedValue => '8',
            },
            {
                Key           => 'ModernizeFormFields',
                JSKey         => 'InputFieldsActivated',
                ExpectedValue => '9',
            },
            {
                Key           => 'Ticket::Frontend::CustomerInfoCompose',
                JSKey         => 'CustomerInfoSet',
                ExpectedValue => '10',
            },
            {
                Key           => 'Ticket::IncludeUnknownTicketCustomers',
                JSKey         => 'IncludeUnknownTicketCustomers',
                ExpectedValue => '11',
            },
        );

        # set the expected values
        TEST:
        for my $Test (@Tests) {

            next TEST if $Test->{Environment};

            # set the item to the expected value
            $Helper->ConfigSettingChange(
                Valid => 1,
                Key   => $Test->{Key},
                Value => $Test->{ExpectedValue}
            );
        }

        # create test user and login
        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => [ 'admin', 'users' ],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # get script alias
        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

        # go to some dummy page
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentTicketPhone");

        for my $Test (@Tests) {

            my $Key = $Test->{JSKey} // $Test->{Key};

            # check value
            $Self->Is(
                $Selenium->execute_script(
                    "return Core.Config.Get('$Key');"
                ),
                $Test->{ExpectedValue},
                "$Key matches expected value.",
            );
        }
    }
);

$Self->DoneTesting();
