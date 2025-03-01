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

package Kernel::GenericInterface::Invoker;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(IsStringWithData);

# Prevent 'Used once' warning for Kernel::OM.
use Kernel::System::ObjectManager;

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::GenericInterface::Invoker - GenericInterface Invoker interface

=head1 DESCRIPTION

Invokers are responsible to prepare for making a remote web service
request.

For every Request, two methods are called:

=over 4

=item L</PrepareRequest()>

=item L</HandleResponse()>

=back

The first method prepares the response and can prevent it by returning
an error state. The second method must always be called if the request
was initiated to allow the Invoker to handle possible errors.

=head1 PUBLIC INTERFACE

=head2 new()

create an object.

    use Kernel::GenericInterface::Debugger;
    use Kernel::GenericInterface::Invoker;

    my $DebuggerObject = Kernel::GenericInterface::Debugger->new(
        DebuggerConfig   => {
            DebugThreshold => 'debug',
            TestMode       => 0,           # optional, in testing mode the data will not be written to the DB
            # ...
        },
        WebserviceID      => 12,
        CommunicationType => Requester, # Requester or Provider
        RemoteIP          => 192.168.1.1, # optional
    );
    my $InvokerObject = Kernel::GenericInterface::Invoker->new(
        DebuggerObject     => $DebuggerObject,
        Invoker            => 'TicketLock',            # the name of the invoker in the web service
        InvokerType        => 'Nagios::TicketLock',    # the Invoker backend to use
        WebserviceID       => 1                        # the WebserviceID where the Invoker belongs
                                                       # normally this is passed by the requester
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # Allocate new hash for object.
    my $Self = {};
    bless( $Self, $Type );

    # Check needed params.
    for my $Needed (qw( DebuggerObject Invoker InvokerType WebserviceID )) {
        if ( !$Param{$Needed} ) {

            return {
                Success      => 0,
                ErrorMessage => "Got no $Needed!"
            };
        }

        $Self->{$Needed} = $Param{$Needed};
    }

    if ( !IsStringWithData( $Param{InvokerType} ) ) {

        return $Self->{DebuggerObject}->Error(
            Summary => 'Got no Invoker Type as string with value!',
        );
    }

    # Load backend module.
    my $GenericModule = 'Kernel::GenericInterface::Invoker::' . $Param{InvokerType};
    if ( !$Kernel::OM->Get('Kernel::System::Main')->Require($GenericModule) ) {

        return $Self->{DebuggerObject}->Error( Summary => "Can't load invoker backend module!" );
    }
    $Self->{BackendObject} = $GenericModule->new( %{$Self} );

    # Pass back error message from backend if backend module could not be executed.
    return $Self->{BackendObject} if ref $Self->{BackendObject} ne $GenericModule;

    return $Self;
}

=head2 PrepareRequest()

prepare the invocation of the configured remote web service.

    my $Result = $InvokerObject->PrepareRequest(
        Data => {                               # data payload
            ...
        },
    );

    $Result = {
        Success         => 1,                   # 0 or 1
        ErrorMessage    => '',                  # in case of error
        Data            => {                    # data payload after Invoker
            ...
        },
    };

    $Result = {
        Success           => 1,                 # 0 or 1
        StopCommunication => 1,                 # in case of is not needed to continue with the
                                                # request (do nothing just exist gracefully)
    };

=cut

sub PrepareRequest {
    my ( $Self, %Param ) = @_;

    # Check data - only accept undef or hash ref or array ref.
    if ( defined $Param{Data} && ref $Param{Data} ne 'HASH' && ref $Param{Data} ne 'ARRAY' ) {

        return $Self->{DebuggerObject}->Error(
            Summary => 'Got Data but it is not a hash or array ref in Invoker handler (PrepareRequest)!'
        );
    }

    # Start map on backend.
    return $Self->{BackendObject}->PrepareRequest(%Param);

}

=head2 HandleResponse()

handle response data of the configured remote web service.

    my $Result = $InvokerObject->HandleResponse(
        ResponseSuccess      => 1,              # success status of the remote web service
        ResponseErrorMessage => '',             # in case of web service error
        Data => {                               # data payload
            ...
        },
    );

    $Result = {
        Success         => 1,                   # 0 or 1
        ErrorMessage    => '',                  # in case of error
        Data            => {                    # data payload after Invoker
            ...
        },
    };

=cut

sub HandleResponse {
    my ( $Self, %Param ) = @_;

    # Check data - only accept undef or hash ref or array ref.
    if ( defined $Param{Data} && ref $Param{Data} ne 'HASH' && ref $Param{Data} ne 'ARRAY' ) {

        return $Self->{DebuggerObject}->Error(
            Summary => 'Got Data but it is not a hash or array ref in Invoker handler (HandleResponse)!'
        );
    }

    # Start map on backend.
    return $Self->{BackendObject}->HandleResponse(%Param);

}

=head2 HandleError()

handle error data of the configured remote web service.

    my $Result = $InvokerObject->HandleError(
        Data => {                               # data payload
            ...
        },
    );

    $Result = {
        Success         => 1,                   # 0 or 1
        ErrorMessage    => '',                  # in case of error
        Data            => {                    # data payload after Invoker
            ...
        },
    };

=cut

sub HandleError {
    my ( $Self, %Param ) = @_;

    # Check data - only accept undef or hash ref or array ref.
    if ( defined $Param{Data} && ref $Param{Data} ne 'HASH' && ref $Param{Data} ne 'ARRAY' ) {

        return $Self->{DebuggerObject}->Error(
            Summary => 'Got Data but it is not a hash or array ref in Invoker handler (HandleResponse)!'
        );
    }

    return $Self->{BackendObject}->HandleError(%Param);

}

1;
