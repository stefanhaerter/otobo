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

# get selenium object
# OTOBO modules
use Kernel::System::UnitTest::Selenium;
my $Selenium = Kernel::System::UnitTest::Selenium->new( LogExecuteCommandActive => 1 );

$Selenium->RunTest(
    sub {

        # get helper object
        my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # get cmd sysconfig params
        my $CmdMessage = 'Selenium cmd output test';
        my %CmdParam   = (
            Block       => 'ContentSmall',
            CacheTTL    => 60,
            Cmd         => 'echo ' . $CmdMessage,
            Default     => 1,
            Description => '',
            Group       => '',
            Module      => 'Kernel::Output::HTML::Dashboard::CmdOutput',
            Title       => 'Sample command output'
        );
        $Helper->ConfigSettingChange(
            Valid => 1,
            Key   => 'DashboardBackend###0420-CmdOutput',
            Value => \%CmdParam,
        );

        # create test user and login
        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => [ 'admin', 'users' ],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # check for cmd expected message
        $Self->True(
            index( $Selenium->get_page_source(), "$CmdMessage" ) > -1,
            "$CmdMessage - found on screen"
        );
    }
);

$Self->DoneTesting();
