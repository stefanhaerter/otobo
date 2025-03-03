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

use Kernel::Language;

# get selenium object
# OTOBO modules
use Kernel::System::UnitTest::Selenium;
my $Selenium = Kernel::System::UnitTest::Selenium->new( LogExecuteCommandActive => 1 );

$Selenium->RunTest(
    sub {

        # get helper object
        my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # enable meta floaters for AgentTicketZoom
        $Helper->ConfigSettingChange(
            Valid => 1,
            Key   => 'Ticket::Frontend::ZoomCollectMeta',
            Value => 1
        );

        my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

        my $SettingName = 'Ticket::Frontend::ZoomCollectMetaFilters###CVE-Mitre';

        my %Setting = $SysConfigObject->SettingGet(
            Name => $SettingName,
        );

        $Helper->ConfigSettingChange(
            Valid => 1,
            Key   => $SettingName,
            Value => $Setting{EffectiveValue},
        );

        my $Language      = 'de';
        my $TestUserLogin = $Helper->TestUserCreate(
            Language => $Language,
            Groups   => [ 'admin', 'users' ],
        ) || die "Did not get test user";

        # get test user ID
        my $TestUserID = $Kernel::OM->Get('Kernel::System::User')->UserLookup(
            UserLogin => $TestUserLogin,
        );

        # create test ticket
        my $TicketID = $Kernel::OM->Get('Kernel::System::Ticket')->TicketCreate(
            Title        => 'Selenium Ticket',
            Queue        => 'Raw',
            Lock         => 'unlock',
            Priority     => '3 normal',
            State        => 'new',
            CustomerID   => '123465',
            CustomerUser => 'customer@example.com',
            OwnerID      => 1,
            UserID       => 1,
        );
        $Self->True(
            $TicketID,
            "TicketCreate - ID $TicketID",
        );

        my @ArticleIDs;

        my $ArticleBackendObject = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForChannel(
            ChannelName => 'Phone',
        );

        my $ArticleIDPlain = $ArticleBackendObject->ArticleCreate(
            TicketID             => $TicketID,
            IsVisibleForCustomer => 0,
            SenderType           => 'agent',
            Subject              => 'Selenium subject test',
            Body                 =>
                'This is a test with some CVE numbers in it. They CVE-353-22 should be recognized correctly and displayed next to the article body: CVE-353-19, CVE-353-13',
            ContentType    => 'text/plain; charset=ISO-8859-15',
            HistoryType    => 'OwnerUpdate',
            HistoryComment => 'Some free text!',
            UserID         => 1,
            NoAgentNotify  => 1,
        );

        $Self->True(
            $ArticleIDPlain,
            "ArticleCreate - ID $ArticleIDPlain",
        );

        push @ArticleIDs, $ArticleIDPlain;

        my $ArticleIDHTML = $ArticleBackendObject->ArticleCreate(
            TicketID             => $TicketID,
            IsVisibleForCustomer => 0,
            SenderType           => 'agent',
            Subject              => 'some short description',
            Body                 =>
                '<p>This is an HTML article containing some CVE-Numbers like <ul><li>CVE-353-19</li><li>CVE-353-13</li></ul></p>',
            ContentType    => 'text/html; charset=ISO-8859-15',
            HistoryType    => 'AddNote',
            HistoryComment => 'Some free text!',
            UserID         => $TestUserID,
        );

        $Self->True(
            $ArticleIDHTML,
            "ArticleCreate - ID $ArticleIDHTML",
        );

        push @ArticleIDs, $ArticleIDHTML;

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # get script alias
        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');

        for my $ArticleID (@ArticleIDs) {

            # navigate to AgentTicketZoom screen of created test ticket
            $Selenium->VerifiedGet(
                "${ScriptAlias}index.pl?Action=AgentTicketZoom;TicketID=$TicketID;ArticleID=$ArticleID"
            );

            # check if we are seeing the meta box
            $Selenium->find_element( ".ArticleMeta", "css" );

            # hover one of the meta elements
            $Selenium->execute_script("\$('.ArticleMeta').first().find('li:first-child a:first-child').mouseenter();");

            # wait for the floater to be fully visible
            $Selenium->WaitFor(
                JavaScript => "return parseInt(\$('div.MetaFloater:visible').css('opacity'), 10) == 1"
            );

            # see if we have a floater visible now
            $Self->Is(
                $Selenium->execute_script("return \$('div.MetaFloater:visible').length"),
                1,
                'Floater is visible'
            );

            # wait for the close button to fade in
            $Selenium->WaitFor( JavaScript => "return \$('.MetaFloater:visible a.Close:visible').length === 1" );

            # close the floater again
            $Selenium->execute_script("\$('.MetaFloater a.Close').click();");

            # wait until the floater is gone
            $Selenium->WaitFor( JavaScript => "return \$('.MetaFloater:visible').length === 0" );
        }
    }
);

$Self->DoneTesting();
