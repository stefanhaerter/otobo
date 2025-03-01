# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2019 OTRS AG, https://otrs.com/
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

# core modules

# CPAN modules
use Test2::V0;

# OTOBO modules
use Kernel::System::UnitTest::RegisterDriver;    # set up $Self and $Kernel::OM
use Kernel::System::UnitTest::Selenium;

our $Self;

my $Selenium = Kernel::System::UnitTest::Selenium->new( LogExecuteCommandActive => 1 );

$Selenium->RunTest(
    sub {
        my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # Create test user and login.
        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => ['admin'],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # Get test user ID.
        my $TestUserID = $Kernel::OM->Get('Kernel::System::User')->UserLookup(
            UserLogin => $TestUserLogin,
        );

        my $ProcessRandom  = 'Process' . $Helper->GetRandomID();
        my $ActivityRandom = 'Activity' . $Helper->GetRandomID();

        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');

        # Navigate to AdminProcessManagement screen.
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AdminProcessManagement");

        # Create new test Process.
        $Selenium->find_element("//a[contains(\@href, \'Subaction=ProcessNew' )]")->VerifiedClick();
        $Selenium->find_element( "#Name",        'css' )->send_keys($ProcessRandom);
        $Selenium->find_element( "#Description", 'css' )->send_keys("Selenium Test Process");
        $Selenium->find_element( "#Submit",      'css' )->VerifiedClick();

        $Selenium->WaitFor( JavaScript => "return typeof(\$) === 'function' && \$('#ProcessDelete').length" );
        my $ProcessID = $Selenium->execute_script('return $("#ProcessDelete").data("id")') || undef;

        $Selenium->find_element( "#Submit", 'css' )->VerifiedClick();

        $Selenium->find_element(
            "//a[contains(\@href,\'AdminProcessManagement;Subaction=ProcessPrint;ID=$ProcessID;\')]"
        )->click();

        $Selenium->WaitFor( WindowCount => 2 );
        my $Handles = $Selenium->get_window_handles();
        $Selenium->switch_to_window( $Handles->[1] );

        # Check process print screen.
        my $ProcessPrintSelector = q{//li[@class='HeaderPopupleft' and contains(text(),'Print process information')]};
        $Selenium->WaitFor( ElementExists => $ProcessPrintSelector );
        ok( $Selenium->find_element($ProcessPrintSelector), "Process print screen is loaded." );

        $Selenium->close();
        $Selenium->WaitFor( WindowCount => 1 );
        $Selenium->switch_to_window( $Handles->[0] );

        # Delete test process.
        my $Success = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process')->ProcessDelete(
            ID     => $ProcessID,
            UserID => $TestUserID,
        );
        $Self->True(
            $Success,
            "Process is deleted - $ProcessID",
        );

        $Selenium->WaitFor( ElementExists => "//a[contains(\@href, \'Subaction=ProcessSync' )]" );

        # Synchronize process after deleting test process.
        $Selenium->find_element("//a[contains(\@href, \'Subaction=ProcessSync' )]")->VerifiedClick();

        my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

        # Make sure cache is correct.
        $CacheObject->CleanUp( Type => 'ProcessManagement_Process' );
    }
);

$Self->DoneTesting();
