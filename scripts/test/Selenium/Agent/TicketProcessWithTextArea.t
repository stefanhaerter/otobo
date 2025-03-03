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
use Kernel::System::VariableCheck qw(IsHashRefWithData);

our $Self;

my $Selenium = Kernel::System::UnitTest::Selenium->new( LogExecuteCommandActive => 1 );

$Selenium->RunTest(
    sub {

        my $Helper             = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
        my $ProcessObject      = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process');

        my $Home = $Kernel::OM->Get('Kernel::Config')->Get("Home");

        my $DynamicFieldGet = $DynamicFieldObject->DynamicFieldGet(
            Name => 'TestTextArea',
        );
        my $DynamicFieldID = $DynamicFieldGet->{ID};
        my $DefaultValue   = "Line 1\nLine 2\nLine 3";

        if ( !IsHashRefWithData($DynamicFieldGet) ) {
            $DynamicFieldID = $DynamicFieldObject->DynamicFieldAdd(
                Name       => "TestTextArea",
                Label      => "TestTextArea",
                FieldOrder => 9999,
                FieldType  => 'TextArea',
                Config     => {
                    DefaultValue => $DefaultValue,
                },
                ObjectType => 'Ticket',
                ValidID    => 1,
                UserID     => 1,
                Reorder    => 0,
            );

            $Self->True(
                $DynamicFieldID,
                "Dynamic field created.",
            );
        }

        # Create test user and login.
        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => [ 'admin', 'users' ],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        my $TestUserID = $Kernel::OM->Get('Kernel::System::User')->UserLookup(
            UserLogin => $TestUserLogin,
        );

        # Get all processes.
        my $ProcessList = $ProcessObject->ProcessListGet(
            UserID => $TestUserID,
        );

        my @DeactivatedProcesses;
        my $ProcessName = "TestProcessTextArea";
        my $TestProcessExists;

        # If there had been some active processes before testing, set them to inactive.
        PROCESS:
        for my $Process ( @{$ProcessList} ) {
            if ( $Process->{State} eq 'Active' ) {

                # Check if active test process already exists.
                if ( $Process->{Name} eq $ProcessName ) {
                    $TestProcessExists = 1;
                    next PROCESS;
                }

                $ProcessObject->ProcessUpdate(
                    ID            => $Process->{ID},
                    EntityID      => $Process->{EntityID},
                    Name          => $Process->{Name},
                    StateEntityID => 'S2',
                    Layout        => $Process->{Layout},
                    Config        => $Process->{Config},
                    UserID        => $TestUserID,
                );

                # Save process because of restoring on the end of test.
                push @DeactivatedProcesses, $Process;
            }
        }

        my $ScriptAlias  = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');
        my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

        # Import test process if does not exist in the system.
        if ( !$TestProcessExists ) {
            $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AdminProcessManagement");
            $Selenium->WaitFor(
                JavaScript => "return typeof(\$) === 'function' && \$('#OverwriteExistingEntitiesImport').length;"
            );

            # Import test Selenium Process.
            my $Location = $ConfigObject->Get('Home')
                . "/scripts/test/sample/ProcessManagement/TestProcessTextArea.yml";
            $Selenium->find_element( "#FileUpload",                      'css' )->send_keys($Location);
            $Selenium->find_element( "#OverwriteExistingEntitiesImport", 'css' )->click();
            $Selenium->WaitFor(
                JavaScript => "return !\$('#OverwriteExistingEntitiesImport:checked').length;"
            );
            $Selenium->find_element("//button[\@value='Upload process configuration'][\@type='submit']")->VerifiedClick();
            $Selenium->find_element("//a[contains(\@href, \'Subaction=ProcessSync' )]")->VerifiedClick();
        }

        # Get Process list.
        my $List = $ProcessObject->ProcessList(
            UseEntities => 1,
            UserID      => $TestUserID,
        );

        # Get Process entity.
        my %ListReverse = reverse %{$List};

        $Kernel::OM->Get('Kernel::System::Log')->Dumper( '%ListReverse', %ListReverse );

        my $Process = $ProcessObject->ProcessGet(
            EntityID => $ListReverse{$ProcessName},
            UserID   => $TestUserID,
        );

        # Navigate to AgentTicketProcess screen.
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentTicketProcess");

        # Create first scenario for test AgentTicketProcess.
        $Selenium->InputFieldValueSet(
            Element => '#ProcessEntityID',
            Value   => $ListReverse{$ProcessName},
        );

        # Wait until form has loaded, if necessary.
        $Selenium->WaitFor(
            ElementExists => q{//button[@value='Submit']}
        );
        $Selenium->find_element(q{//button[@value='Submit']})->click();
        $Selenium->WaitFor(
            JavaScript => "return typeof(\$) === 'function' && \$('.ArticleID').length;"
        );

        my $ArticleID = $Selenium->execute_script(
            "return \$('.Subject:contains(\"This is the subject\")').closest('tr').find('.ArticleID').val();"
        );

        my @Ticket   = split( 'TicketID=', $Selenium->get_current_url() );
        my $TicketID = $Ticket[1];

        my $ArticleBackendObject = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForChannel(
            ChannelName => 'Email',
        );
        my %Article = $ArticleBackendObject->ArticleGet(
            TicketID  => $TicketID,
            ArticleID => $ArticleID,
        );

        # Check article body created in transition action of the test ticket.
        # See bug#14229 for more information.
        $Self->True(
            index( $Article{Body}, $DefaultValue ) > -1,
            "Article body is created well.",
        );

        # Remember created ticket, to delete the ticket at the end of the test.
        my @DeleteTicketIDs;
        ( undef, my $DeleteTicketID ) = split /TicketID=/, $Selenium->get_current_url();
        push @DeleteTicketIDs, $DeleteTicketID;

        my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

        for my $TicketID (@DeleteTicketIDs) {

            my $Success = $TicketObject->TicketDelete(
                TicketID => $TicketID,
                UserID   => $TestUserID,
            );

            # Ticket deletion could fail if apache still writes to ticket history. Try again in this case.
            if ( !$Success ) {
                sleep 3;
                $Success = $TicketObject->TicketDelete(
                    TicketID => $TicketID,
                    UserID   => $TestUserID,
                );
            }
            ok( $Success, "TicketID $TicketID is deleted" );
        }

        # Delete the dynamic field values.
        my $Success = $Kernel::OM->Get('Kernel::System::DynamicFieldValue')->AllValuesDelete(
            FieldID => $DynamicFieldID,
            UserID  => 1,
        );
        ok( $Success, "Dynamic field values deleted successfully - $DynamicFieldID." );

        # Delete dynamic field.
        $Success = $DynamicFieldObject->DynamicFieldDelete(
            ID      => $DynamicFieldID,
            UserID  => 1,
            Reorder => 1,
        );
        ok( $Success, "Dynamic field deleted successfully - $DynamicFieldID." );

        # Clean up activities.
        my $ActivityObject       = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Activity');
        my $ActivityDialogObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::ActivityDialog');
        for my $Item ( @{ $Process->{Activities} } ) {
            my $Activity = $ActivityObject->ActivityGet(
                EntityID            => $Item,
                UserID              => $TestUserID,
                ActivityDialogNames => 0,
            );

            # Clean up activity dialogs.
            for my $ActivityDialogItem ( @{ $Activity->{ActivityDialogs} } ) {
                my $ActivityDialog = $ActivityDialogObject->ActivityDialogGet(
                    EntityID => $ActivityDialogItem,
                    UserID   => $TestUserID,
                );

                # Delete test activity dialog.
                $Success = $ActivityDialogObject->ActivityDialogDelete(
                    ID     => $ActivityDialog->{ID},
                    UserID => $TestUserID,
                );
                $Self->True(
                    $Success,
                    "ActivityDialog $ActivityDialog->{Name} is deleted",
                );
            }

            # Delete test activity.
            $Success = $ActivityObject->ActivityDelete(
                ID     => $Activity->{ID},
                UserID => $TestUserID,
            );

            $Self->True(
                $Success,
                "Activity $Activity->{Name} is deleted",
            );
        }

        # Clean up transition actions
        my $TransitionActionsObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::TransitionAction');
        for my $Item ( @{ $Process->{TransitionActions} } ) {
            my $TransitionAction = $TransitionActionsObject->TransitionActionGet(
                EntityID => $Item,
                UserID   => $TestUserID,
            );

            # Delete test transition action.
            $Success = $TransitionActionsObject->TransitionActionDelete(
                ID     => $TransitionAction->{ID},
                UserID => $TestUserID,
            );

            $Self->True(
                $Success,
                "TransitionAction $TransitionAction->{Name} is deleted",
            );
        }

        # Clean up transition.
        my $TransitionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Transition');
        for my $Item ( @{ $Process->{Transitions} } ) {
            my $Transition = $TransitionObject->TransitionGet(
                EntityID => $Item,
                UserID   => $TestUserID,
            );

            # Delete test transition.
            $Success = $TransitionObject->TransitionDelete(
                ID     => $Transition->{ID},
                UserID => $TestUserID,
            );

            $Self->True(
                $Success,
                "Transition $Transition->{Name} is deleted",
            );
        }

        # Delete test Process.
        $Success = $ProcessObject->ProcessDelete(
            ID     => $Process->{ID},
            UserID => $TestUserID,
        );
        $Self->True(
            $Success,
            "Process $Process->{Name} is deleted",
        );

        # Restore state of process.
        for my $Process (@DeactivatedProcesses) {
            $ProcessObject->ProcessUpdate(
                ID            => $Process->{ID},
                EntityID      => $Process->{EntityID},
                Name          => $Process->{Name},
                StateEntityID => 'S1',
                Layout        => $Process->{Layout},
                Config        => $Process->{Config},
                UserID        => $TestUserID,
            );
        }

        my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

        # Make sure the cache is correct.
        $CacheObject->CleanUp( Type => "ProcessManagement*" );
    }
);

done_testing();
