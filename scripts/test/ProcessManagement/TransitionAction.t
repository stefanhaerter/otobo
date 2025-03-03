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

use Kernel::System::VariableCheck qw(:all);

# get needed objects
my $ConfigObject           = $Kernel::OM->Get('Kernel::Config');
my $TransitionActionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction');

# define needed variables
my $RandomID = $Kernel::OM->Get('Kernel::System::UnitTest::Helper')->GetRandomID();

# TransitionActionGet() tests
my @Tests = (
    {
        Name              => 'No Parameters',
        TransitionActions => {
            'TA1' . $RandomID => {
                Name   => 'Queue Move',
                Module => 'Kernel::System::ProcessManagement::TransitionAction::TicketQueueSet',
                Config => {
                    Queue => 'Misc',
                },
            },
        },
        Config  => {},
        Success => 0,
    },
    {
        Name              => 'No TransitionActionEntityID',
        TransitionActions => {
            'TA1' . $RandomID => {
                Name   => 'Queue Move',
                Module => 'Kernel::System::ProcessManagement::TransitionAction::TicketQueueSet',
                Config => {
                    Queue => 'Misc',
                },
            },
        },
        Config => {
            Other => 1,
        },
        Success => 0,
    },
    {
        Name              => 'Wrong TransitionActionEntityID',
        TransitionActions => {
            'TA1' . $RandomID => {
                Name   => 'Queue Move',
                Module => 'Kernel::System::ProcessManagement::TransitionAction::TicketQueueSet',
                Config => {
                    Queue => 'Misc',
                },
            },
        },
        Config => {
            TransitionActionEntityID => 'Notexisiting' . $RandomID,
        },
        Success => 0,
    },
    {
        Name              => 'No TransitionActions Configuration',
        TransitionActions => {},
        Config            => {
            TransitionActionEntityID => 'TA1' . $RandomID,
        },
        Success => 0,
    },
    {
        Name              => 'Wrong Module',
        TransitionActions => {
            'TA1' . $RandomID => {
                Name   => 'Queue Move',
                Module => 'Kernel::System::ProcessManagement::TransitionAction::NotExistingModule',
                Config => {
                    Queue => 'Misc',
                },
            },
        },
        Config => {
            TransitionActionEntityID => 'TA1' . $RandomID,
        },
        Success => 0,
    },
    {
        Name              => 'Correct ASCII',
        TransitionActions => {
            'TA1' . $RandomID => {
                Name   => 'Queue Move',
                Module => 'Kernel::System::ProcessManagement::TransitionAction::TicketQueueSet',
                Config => {
                    Queue => 'Misc',
                },
            },
        },
        Config => {
            TransitionActionEntityID => 'TA1' . $RandomID,
        },
        Success => 1,
    },
    {
        Name              => 'Correct UTF8',
        TransitionActions => {
            'TA1' . $RandomID => {
                Name =>
                    'äöüßÄÖÜ€исáéíúóúÁÉÍÓÚñÑ-カスタ-用迎使用-Язык',
                Module => 'Kernel::System::ProcessManagement::TransitionAction::TicketQueueSet',
                Config => {
                    Queue => 'Raw',
                },
            },
        },
        Config => {
            TransitionActionEntityID => 'TA1' . $RandomID,
        },
        Success => 1,
    },
);

for my $Test (@Tests) {

    # set transition action config
    $ConfigObject->Set(
        Key   => 'Process::TransitionAction',
        Value => $Test->{TransitionActions},
    );

    # get transition action described in test
    my $TransitionAction = $TransitionActionObject->TransitionActionGet( %{ $Test->{Config} } );

    if ( $Test->{Success} ) {
        $Self->IsNot(
            $TransitionAction,
            undef,
            "TransitionActionGet() Test:'$Test->{Name}' | should not be undef"
        );
        $Self->Is(
            ref $TransitionAction,
            'HASH',
            "TransitionActionGet() Test:'$Test->{Name}' | should be a HASH"
        );
        $Self->IsDeeply(
            $TransitionAction,
            $Test->{TransitionActions}->{ $Test->{Config}->{TransitionActionEntityID} },
            "TransitionActionGet() Test:'$Test->{Name}' | comparison"
        );
    }
    else {
        $Self->Is(
            $TransitionAction,
            undef,
            "TransitionActionGet() Test:'$Test->{Name}' | should be undef"
        );
    }
}

# TransitionActionList() tests
@Tests = (
    {
        Name              => 'No Params',
        TransitionActions => {
            'TA1' . $RandomID => {
                Name   => 'Queue Move',
                Module => 'Kernel::System::ProcessManagement::TransitionAction::TicketQueueSet',
                Config => {
                    Queue => 'Misc',
                },
            },
        },
        Config  => {},
        Success => 0,
    },
    {
        Name              => 'No TransitionActionEntityID',
        TransitionActions => {
            'TA1' . $RandomID => {
                Name   => 'Queue Move',
                Module => 'Kernel::System::ProcessManagement::TransitionAction::TicketQueueSet',
                Config => {
                    Queue => 'Misc',
                },
            },
        },
        Config => {
            Other => 1,
        },
        Success => 0,
    },
    {
        Name              => 'Wrong TransitionActionEntityID format',
        TransitionActions => {
            'TA1' . $RandomID => {
                Name   => 'Queue Move',
                Module => 'Kernel::System::ProcessManagement::TransitionAction::TicketQueueSet',
                Config => {
                    Queue => 'Misc',
                },
            },
        },
        Config => {
            TransitionActionEntityID => 'TA1' . $RandomID,
        },
        Success => 0,
    },
    {
        Name              => 'Wrong TransitionActionEntityID',
        TransitionActions => {
            'TA1' . $RandomID => {
                Name   => 'Queue Move',
                Module => 'Kernel::System::ProcessManagement::TransitionAction::TicketQueueSet',
                Config => {
                    Queue => 'Misc',
                },
            },
        },
        Config => {
            TransitionActionEntityID => [ 'NotExistent' . $RandomID ],
        },
        Success => 0,
    },
    {
        Name              => 'Wrong TransitionAction Module',
        TransitionActions => {
            'TA1' . $RandomID => {
                Name   => 'Queue Move',
                Module => 'Kernel::System::ProcessManagement::TransitionAction::NotExisiting',
                Config => {
                    Queue => 'Misc',
                },
            },
        },
        Config => {
            TransitionActionEntityID => [ 'TA1' . $RandomID ],
        },
        Success => 0,
    },
    {
        Name              => 'Correct Single',
        TransitionActions => {
            'TA1' . $RandomID => {
                Name   => 'Queue Move',
                Module => 'Kernel::System::ProcessManagement::TransitionAction::TicketQueueSet',
                Config => {
                    Queue => 'Misc',
                },
            },
            'TA2' . $RandomID => {
                Name   => 'Customer Set',
                Module => 'Kernel::System::ProcessManagement::TransitionAction::TicketCustomerSet',
                Config => {
                    Param1 => 1,
                },
            },
            'TA3' . $RandomID => {
                Name   => 'Article Create',
                Module =>
                    'Kernel::System::ProcessManagement::TransitionAction::TicketArticleCreate',
                Config => {
                    Param1 => 1,
                },
            },
        },
        Config => {
            TransitionActionEntityID => [ 'TA1' . $RandomID ],
        },
        Success => 1,
    },
    {
        Name              => 'Correct Multiple 2TA',
        TransitionActions => {
            'TA1' . $RandomID => {
                Name   => 'Queue Move',
                Module => 'Kernel::System::ProcessManagement::TransitionAction::TicketQueueSet',
                Config => {
                    Queue => 'Misc',
                },
            },
            'TA2' . $RandomID => {
                Name   => 'Customer Set',
                Module => 'Kernel::System::ProcessManagement::TransitionAction::TicketCustomerSet',
                Config => {
                    Param1 => 1,
                },
            },
            'TA3' . $RandomID => {
                Name   => 'Article Create',
                Module =>
                    'Kernel::System::ProcessManagement::TransitionAction::TicketArticleCreate',
                Config => {
                    Param1 => 1,
                },
            },
        },
        Config => {
            TransitionActionEntityID => [
                'TA2' . $RandomID,
                'TA1' . $RandomID,
            ],
        },
        Success => 1,
    },
    {
        Name              => 'Correct Multiple 3TA',
        TransitionActions => {
            'TA1' . $RandomID => {
                Name   => 'Queue Move',
                Module => 'Kernel::System::ProcessManagement::TransitionAction::TicketQueueSet',
                Config => {
                    Queue => 'Misc',
                },
            },
            'TA2' . $RandomID => {
                Name   => 'Customer Set',
                Module => 'Kernel::System::ProcessManagement::TransitionAction::TicketCustomerSet',
                Config => {
                    Param1 => 1,
                },
            },
            'TA3' . $RandomID => {
                Name   => 'Article Create',
                Module =>
                    'Kernel::System::ProcessManagement::TransitionAction::TicketArticleCreate',
                Config => {
                    Param1 => 1,
                },
            },
        },
        Config => {
            TransitionActionEntityID => [
                'TA1' . $RandomID,
                'TA2' . $RandomID,
                'TA3' . $RandomID,
            ],
        },
        Success => 1,
    },
);

for my $Test (@Tests) {

    # set activity config
    $ConfigObject->Set(
        Key   => 'Process::TransitionAction',
        Value => $Test->{TransitionActions},
    );

    # list get transition actions
    my $TransitionActionList = $TransitionActionObject->TransitionActionList( %{ $Test->{Config} } );

    if ( $Test->{Success} ) {
        $Self->IsNot(
            $TransitionActionList,
            undef,
            "TransitionActionList() Test:'$Test->{Name}' | should not be undef"
        );
        $Self->Is(
            ref $TransitionActionList,
            'ARRAY',
            "TransitionActionList() Test:'$Test->{Name}' | should be an ARRAY"
        );

        my @ExpectedTransitionActions;

        ENTITYID:
        for my $TransitionActionEntityID ( @{ $Test->{Config}->{TransitionActionEntityID} } ) {
            next ENTITYID if !$TransitionActionEntityID;

            # get the transition action form test config
            my %TransitionAction = %{ $Test->{TransitionActions}->{$TransitionActionEntityID} };

            # add the entity ID
            $TransitionAction{TransitionActionEntityID} = $TransitionActionEntityID;
            push @ExpectedTransitionActions, \%TransitionAction;
        }

        $Self->IsDeeply(
            $TransitionActionList,
            \@ExpectedTransitionActions,
            "TransitionActionList() Test:'$Test->{Name}' | comparison"
        );
    }
    else {
        $Self->Is(
            $TransitionActionList,
            undef,
            "TransitionActionList() Test:'$Test->{Name}' | should be undef"
        );
    }
}

$Self->DoneTesting();
