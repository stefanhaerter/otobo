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
use v5.24;
use utf8;

# core modules

# CPAN modules
use Test2::V0;

# OTOBO modules
use Kernel::System::UnitTest::RegisterDriver;    # Set up $Self and $Kernel::OM
use Kernel::System::UnitTest::Selenium;
use Kernel::GenericInterface::Operation::Session::Common;

our $Self;

my $Selenium = Kernel::System::UnitTest::Selenium->new( LogExecuteCommandActive => 1 );

# Cleanup existing settings to make sure session limit calculations are correct.
my $AuthSessionObject = $Kernel::OM->Get('Kernel::System::AuthSession');
for my $SessionID ( $AuthSessionObject->GetAllSessionIDs() ) {
    $AuthSessionObject->RemoveSessionID( SessionID => $SessionID );
}

$Selenium->RunTest(
    sub {

        my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # Disable autocomplete in login form.
        $Helper->ConfigSettingChange(
            Key   => 'DisableLoginAutocomplete',
            Value => 1,
        );

        my @TestUserLogins;

        # Create test users.
        for ( 0 .. 2 ) {
            my $TestUserLogin = $Helper->TestUserCreate(
                Groups => [ 'admin', 'users' ],
            ) || die "Did not get test user";

            push @TestUserLogins, $TestUserLogin;
        }

        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');

        # First load the page so we can delete any pre-existing cookies.
        $Selenium->VerifiedGet("${ScriptAlias}index.pl");
        $Selenium->delete_all_cookies();

        # Check Secure::DisableBanner functionality.
        my $Product = $Kernel::OM->Get('Kernel::Config')->Get('Product');
        my $Version = $Kernel::OM->Get('Kernel::Config')->Get('Version');

        for my $Disabled ( reverse 0 .. 1 ) {
            $Helper->ConfigSettingChange(
                Key   => 'Secure::DisableBanner',
                Value => $Disabled,
            );
            $Selenium->VerifiedRefresh();

            if ($Disabled) {
                $Self->False(
                    index( $Selenium->get_page_source(), 'Powered' ) > -1,
                    'Footer banner hidden',
                );
            }
            else {

                $Self->True(
                    index( $Selenium->get_page_source(), 'Powered' ) > -1,
                    'Footer banner shown',
                );

                # Prevent version information disclosure on login page.
                $Self->False(
                    index( $Selenium->get_page_source(), "$Product $Version" ) > -1,
                    "No version information disclosure ($Product $Version)",
                );
            }
        }

        # Check if autocomplete is disabled in login form.
        $Self->True(
            $Selenium->find_element("//input[\@name=\'User\'][\@autocomplete=\'off\']"),
            'Autocomplete for username input field is disabled.'
        );
        $Self->True(
            $Selenium->find_element("//input[\@name=\'Password\'][\@autocomplete=\'off\']"),
            'Autocomplete for password input field is disabled.'
        );

        my $Element = $Selenium->find_element( 'input#User', 'css' );
        $Element->is_displayed();
        $Element->is_enabled();
        $Element->send_keys( $TestUserLogins[0] );

        $Element = $Selenium->find_element( 'input#Password', 'css' );
        $Element->is_displayed();
        $Element->is_enabled();
        $Element->send_keys( $TestUserLogins[0] );

        # Login.
        $Selenium->find_element( '#LoginButton', 'css' )->VerifiedClick();

        # Try to expand the user profile sub menu by clicking the avatar.
        $Selenium->find_element( '.UserAvatar > a', 'css' )->click();
        $Selenium->WaitFor(
            JavaScript => 'return typeof($) === "function" && $("li.UserAvatar > div:visible").length'
        );

        # Check if we see the logout button.
        $Element = $Selenium->find_element( 'a#LogoutButton', 'css' );

        # Check for version tag in the footer.
        $Self->True(
            index( $Selenium->get_page_source(), "$Product $Version" ) > -1,
            "Version information present ($Product $Version)",
        );

        # Logout again.
        $Element->VerifiedClick();

        my @SessionIDs;

        my $SessionObject = $Kernel::OM->Get('Kernel::System::AuthSession');

        for my $Counter ( 1 .. 2 ) {

            # Create new session id.
            my $NewSessionID = $SessionObject->CreateSessionID(
                UserLogin       => $TestUserLogins[$Counter],
                UserLastRequest => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch(),
                UserType        => 'User',
            );

            $Self->True(
                $NewSessionID,
                "Create SessionID for user '$TestUserLogins[$Counter]'",
            );

            push @SessionIDs, $NewSessionID;
        }

        # Create also two webservice session, to check that the sessions are not influence the active sessions and limit check.
        for my $Counter ( 1 .. 2 ) {

            my $NewSessionID = Kernel::GenericInterface::Operation::Session::Common->CreateSessionID(
                Data => {
                    UserLogin => $TestUserLogins[$Counter],
                    Password  => $TestUserLogins[$Counter],
                },
            );

            $Self->True(
                $NewSessionID,
                "Create webservice SessionID for user '$TestUserLogins[$Counter]'",
            );
        }

        $Helper->ConfigSettingChange(
            Key   => 'AgentSessionLimitPriorWarning',
            Value => 1,
        );

        $Element = $Selenium->find_element( 'input#User', 'css' );
        $Element->is_displayed();
        $Element->is_enabled();
        $Element->send_keys( $TestUserLogins[0] );

        $Element = $Selenium->find_element( 'input#Password', 'css' );
        $Element->is_displayed();
        $Element->is_enabled();
        $Element->send_keys( $TestUserLogins[0] );

        $Selenium->find_element( '#LoginButton', 'css' )->VerifiedClick();

        # Check for the prior warning.
        my $PageSource = $Selenium->get_page_source();
        {
            my $ToDo = todo('no session limit in OTOBO, issue #734');

            ok(
                index( $PageSource, 'Please note that the session limit is almost reached.' ) > -1,
                "AgentSessionLimitPriorWarning is reached.",
            );
        }

        # Try to expand the user profile sub menu by clicking the avatar.
        $Selenium->find_element( '.UserAvatar > a', 'css' )->click();
        $Selenium->WaitFor(
            JavaScript => 'return typeof($) === "function" && $("li.UserAvatar > div:visible").length'
        );

        # Enable autocomplete in login form.
        $Helper->ConfigSettingChange(
            Key   => 'DisableLoginAutocomplete',
            Value => 0,
        );

        $Element = $Selenium->find_element( 'a#LogoutButton', 'css' );
        $Element->VerifiedClick();

        $Helper->ConfigSettingChange(
            Key   => 'AgentSessionPerUserLimit',
            Value => 1,
        );

        # Check if autocomplete is enabled in login form.
        $Self->True(
            $Selenium->find_element("//input[\@name=\'User\'][\@autocomplete=\'username\']"),
            'Autocomplete for username input field is enabled.'
        );
        $Self->True(
            $Selenium->find_element("//input[\@name=\'Password\'][\@autocomplete=\'current-password\']"),
            'Autocomplete for password input field is enabled.'
        );

        $Element = $Selenium->find_element( 'input#User', 'css' );
        $Element->is_displayed();
        $Element->is_enabled();
        $Element->send_keys( $TestUserLogins[2] );

        $Element = $Selenium->find_element( 'input#Password', 'css' );
        $Element->is_displayed();
        $Element->is_enabled();
        $Element->send_keys( $TestUserLogins[2] );

        $Selenium->find_element( '#LoginButton', 'css' )->VerifiedClick();

        $Self->True(
            index( $Selenium->get_page_source(), 'Session per user limit reached!' ) > -1,
            "AgentSessionPerUserLimit is reached.",
        );

        $Helper->ConfigSettingChange(
            Key   => 'AgentSessionLimit',
            Value => 2,
        );

        $Element = $Selenium->find_element( 'input#User', 'css' );
        $Element->is_displayed();
        $Element->is_enabled();
        $Element->send_keys( $TestUserLogins[0] );

        $Element = $Selenium->find_element( 'input#Password', 'css' );
        $Element->is_displayed();
        $Element->is_enabled();
        $Element->send_keys( $TestUserLogins[0] );

        $Selenium->find_element( '#LoginButton', 'css' )->VerifiedClick();

        $Self->True(
            index( $Selenium->get_page_source(), 'Session limit reached! Please try again later.' ) > -1,
            "AgentSessionLimit is reached.",
        );

        # Check if login works with a higher limit and that the webservice sessions have no influence on the limit.
        $Helper->ConfigSettingChange(
            Key   => 'AgentSessionLimit',
            Value => 3,
        );

        $Element = $Selenium->find_element( 'input#User', 'css' );
        $Element->is_displayed();
        $Element->is_enabled();
        $Element->send_keys( $TestUserLogins[0] );

        $Element = $Selenium->find_element( 'input#Password', 'css' );
        $Element->is_displayed();
        $Element->is_enabled();
        $Element->send_keys( $TestUserLogins[0] );

        $Selenium->find_element( '#LoginButton', 'css' )->VerifiedClick();

        # Try to expand the user profile sub menu by clicking the avatar.
        $Selenium->find_element( '.UserAvatar > a', 'css' )->click();
        $Selenium->WaitFor(
            JavaScript => 'return typeof($) === "function" && $("li.UserAvatar > div:visible").length'
        );

        # Login successful?
        $Element = $Selenium->find_element( 'a#LogoutButton', 'css' );

        $SessionObject->CleanUp();
    }
);

done_testing();
