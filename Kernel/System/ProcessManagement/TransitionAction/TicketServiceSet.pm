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

package Kernel::System::ProcessManagement::TransitionAction::TicketServiceSet;

use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::ProcessManagement::TransitionAction::Base);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Service',
    'Kernel::System::Ticket',
    'Kernel::Config',
);

=head1 NAME

Kernel::System::ProcessManagement::TransitionAction::TicketServiceSet - A module to set the ticket Service

=head1 DESCRIPTION

All TicketServiceSet functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $TicketServiceSetObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::TicketServiceSet');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 Run()

    Run Data

    my $TicketServiceSetResult = $TicketServiceSetActionObject->Run(
        UserID                   => 123,
        Ticket                   => \%Ticket,   # required
        ProcessEntityID          => 'P123',
        ActivityEntityID         => 'A123',
        TransitionEntityID       => 'T123',
        TransitionActionEntityID => 'TA123',
        Config                   => {
            Service => 'MyService::Subservice',
            # or
            ServiceID => 123,
            UserID    => 123,                   # optional, to override the UserID from the logged user
        }
    );
    Ticket contains the result of TicketGet including DynamicFields
    Config is the Config Hash stored in a Process::TransitionAction's  Config key
    Returns:

    $TicketServiceSetResult = 1; # 0

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    # define a common message to output in case of any error
    my $CommonMessage = "Process: $Param{ProcessEntityID} Activity: $Param{ActivityEntityID}"
        . " Transition: $Param{TransitionEntityID}"
        . " TransitionAction: $Param{TransitionActionEntityID} - ";

    # check for missing or wrong params
    my $Success = $Self->_CheckParams(
        %Param,
        CommonMessage => $CommonMessage,
    );
    return if !$Success;

    # override UserID if specified as a parameter in the TA config
    $Param{UserID} = $Self->_OverrideUserID(%Param);

    # use ticket attributes if needed
    $Self->_ReplaceTicketAttributes(%Param);
    $Self->_ReplaceAdditionalAttributes(%Param);

    if ( !$Param{Config}->{ServiceID} && !$Param{Config}->{Service} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $CommonMessage . "No Service or ServiceID configured!",
        );
        return;
    }

    if (
        !$Param{Ticket}->{CustomerUserID}
        && !$Kernel::OM->Get('Kernel::Config')->Get('Ticket::Service::Default::UnknownCustomer')
        )
    {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $CommonMessage . "To set a service the ticket requires a customer!",
        );
        return;
    }

    $Success = 0;

    # If Ticket's ServiceID is already the same as the Value we
    # should set it to, we got nothing to do and return success
    if (
        defined $Param{Config}->{ServiceID}
        && defined $Param{Ticket}->{ServiceID}
        && $Param{Config}->{ServiceID} eq $Param{Ticket}->{ServiceID}
        )
    {
        return 1;
    }

    # If Ticket's ServiceID is not the same as the Value we
    # should set it to, set the ServiceID
    elsif (
        (
            defined $Param{Config}->{ServiceID}
            && defined $Param{Ticket}->{ServiceID}
            && $Param{Config}->{ServiceID} ne $Param{Ticket}->{ServiceID}
        )
        || !defined $Param{Ticket}->{ServiceID}
        )
    {

        # check if serivce is assigned to Customer User otherwise return
        $Success = $Self->_CheckService(
            UserLogin => $Param{Ticket}->{CustomerUserID},
            ServiceID => $Param{Config}->{ServiceID}
        );

        if ( !$Success ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => $CommonMessage
                    . 'ServiceID '
                    . $Param{Config}->{ServiceID}
                    . ' is not assigned to Customer User '
                    . $Param{Ticket}->{CustomerUserID}
            );
            return;
        }

        # set ticket service
        $Success = $Kernel::OM->Get('Kernel::System::Ticket')->TicketServiceSet(
            TicketID  => $Param{Ticket}->{TicketID},
            ServiceID => $Param{Config}->{ServiceID},
            UserID    => $Param{UserID},
        );

        if ( !$Success ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => $CommonMessage
                    . 'Ticket ServiceID '
                    . $Param{Config}->{ServiceID}
                    . ' could not be updated for Ticket: '
                    . $Param{Ticket}->{TicketID} . '!',
            );
        }
    }

    # If Ticket's Service is already the same as the Value we
    # should set it to, we got nothing to do and return success
    elsif (
        defined $Param{Config}->{Service}
        && defined $Param{Ticket}->{Service}
        && $Param{Config}->{Service} eq $Param{Ticket}->{Service}
        )
    {
        return 1;
    }

    # If Ticket's Service is not the same as the Value we
    # should set it to, set the Service
    elsif (
        (
            defined $Param{Config}->{Service}
            && defined $Param{Ticket}->{Service}
            && $Param{Config}->{Service} ne $Param{Ticket}->{Service}
        )
        || !defined $Param{Ticket}->{Service}

        )
    {

        my $ServiceID = $Kernel::OM->Get('Kernel::System::Service')->ServiceLookup(
            Name => $Param{Config}->{Service},
        );

        if ( !$ServiceID ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => $CommonMessage
                    . 'Service '
                    . $Param{Config}->{Service}
                    . ' is invalid!'
            );
            return;
        }

        # check if service is assigned to Customer User, otherwise return
        $Success = $Self->_CheckService(
            UserLogin => $Param{Ticket}->{CustomerUserID},
            ServiceID => $ServiceID,
        );

        if ( !$Success ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => $CommonMessage
                    . 'Service '
                    . $Param{Config}->{Service}
                    . ' is not assigned to Customer User '
                    . $Param{Ticket}->{CustomerUserID}
            );
            return;
        }

        # set ticket service
        $Success = $Kernel::OM->Get('Kernel::System::Ticket')->TicketServiceSet(
            TicketID => $Param{Ticket}->{TicketID},
            Service  => $Param{Config}->{Service},
            UserID   => $Param{UserID},
        );

        if ( !$Success ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => $CommonMessage
                    . 'Ticket Service '
                    . $Param{Config}->{Service}
                    . ' could not be updated for Ticket: '
                    . $Param{Ticket}->{TicketID} . '!',
            );
        }
    }
    else {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $CommonMessage
                . "Couldn't update Ticket Service - can't find valid Service parameter!",
        );
        return;
    }

    return $Success;
}

=begin Internal:

=head2 _CheckService()

checks if a service is assigned to a customer user

    my $Success = _CheckService(
        UserLogin => 'some user',
        ServiceID => 123,
    );

    Returns:

    $Success = 1;       # or undef

=cut

sub _CheckService {
    my ( $Self, %Param ) = @_;

    # get a list of assigned services to the customer user
    my %Services = $Kernel::OM->Get('Kernel::System::Service')->CustomerUserServiceMemberList(
        CustomerUserLogin => $Param{UserLogin},
        Result            => 'HASH',
        DefaultServices   => 1,
    );

    # return failure if there are no assigned services for this customer user
    return if !IsHashRefWithData( \%Services );

    # return failure if the the service is not assigned to the customer
    return if !$Services{ $Param{ServiceID} };

    # otherwise return success
    return 1;
}

=end Internal:

=cut

1;
