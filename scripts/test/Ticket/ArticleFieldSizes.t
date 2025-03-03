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

my $ConfigObject          = $Kernel::OM->Get('Kernel::Config');
my $MainObject            = $Kernel::OM->Get('Kernel::System::Main');
my $ArticleInternalObject = $Kernel::OM->Get('Kernel::System::Ticket::Article::Backend::Internal');

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# testing ArticleSend, especially for bug#8828 (attachments)
# create a ticket first
my $TicketID = $Kernel::OM->Get('Kernel::System::Ticket')->TicketCreate(
    Title        => 'Some Ticket_Title',
    Queue        => 'Raw',
    Lock         => 'unlock',
    Priority     => '3 normal',
    State        => 'closed successful',
    CustomerNo   => '123465',
    CustomerUser => 'customer@example.com',
    OwnerID      => 1,
    UserID       => 1,
);

$Self->True(
    $TicketID,
    'TicketCreate()',
);

my $SmallEmail     = ( 'x' x 900 ) . '@localunittest.com';
my $SmallReference = "<$SmallEmail>";

my $MediumEmail     = join( ',', ( ($SmallEmail) x 20 ) );
my $MediumReference = $SmallReference x 20;

my $LargeEmail     = join( ',', ( ($SmallEmail) x 200 ) );
my $LargeReference = $SmallReference x 200;

my @ArticleTests = (
    {
        Name        => 'Article with all fields < 998',
        ArticleData => {
            IsVisibleForCustomer => 0,
            SenderType           => 'agent',
            From                 => $SmallEmail,
            To                   => $SmallEmail,
            Cc                   => $SmallEmail,
            Bcc                  => $SmallEmail,
            ReplyTo              => $SmallEmail,
            MessageID            => $SmallReference,
            References           => $SmallReference,
            InReplyTo            => $SmallReference,
            Subject              => 'some short description',
            Body                 => 'the message text',
            Charset              => 'iso-8859-15',
            MimeType             => 'text/plain',
            Loop                 => 0,
            HistoryType          => 'AddNote',
            HistoryComment       => 'Some free text!',
            UserID               => 1,
        },
    },
    {
        Name        => 'Article with allowed fields > 3800 (bug#5420)',
        ArticleData => {
            IsVisibleForCustomer => 0,
            SenderType           => 'agent',
            From                 => $MediumEmail,
            To                   => $MediumEmail,
            Cc                   => $MediumEmail,
            Bcc                  => $MediumEmail,
            ReplyTo              => $MediumEmail,
            MessageID            => $SmallReference,
            References           => $MediumReference,
            InReplyTo            => $MediumReference,
            Subject              => 'some short description',
            Body                 => 'the message text',
            Charset              => 'iso-8859-15',
            MimeType             => 'text/plain',
            Loop                 => 0,
            HistoryType          => 'AddNote',
            HistoryComment       => 'Some free text!',
            UserID               => 1,
        },
    },
    {
        Name        => 'Article with huge fields (bug#5420)',
        ArticleData => {
            IsVisibleForCustomer => 0,
            SenderType           => 'agent',
            From                 => $LargeEmail,
            To                   => $LargeEmail,
            Cc                   => $LargeEmail,
            Bcc                  => $LargeEmail,
            ReplyTo              => $LargeEmail,
            MessageID            => $SmallReference,
            References           => $LargeReference,
            InReplyTo            => $LargeReference,
            Subject              => 'some short description',
            Body                 => 'the message text',
            Charset              => 'iso-8859-15',
            MimeType             => 'text/plain',
            Loop                 => 0,
            HistoryType          => 'AddNote',
            HistoryComment       => 'Some free text!',
            UserID               => 1,
        },
    },
);

my %Article;
my $ArticleID;
my $ArticleCount = 0;

TEST:
for my $Test (@ArticleTests) {

    # create article
    $ArticleID = $ArticleInternalObject->ArticleCreate(
        TicketID => $TicketID,
        %{ $Test->{ArticleData} },
    );

    $Self->True(
        $ArticleID,
        "$Test->{Name} - ArticleCreate()",
    );

    my %Article = $ArticleInternalObject->ArticleGet(
        TicketID  => $TicketID,
        ArticleID => $ArticleID,
    );

    KEY:
    for my $Key ( sort keys %{ $Test->{ArticleData} } ) {
        next KEY if $Key eq 'HistoryType';
        next KEY if $Key eq 'HistoryComment';
        next KEY if $Key eq 'UserID';
        next KEY if $Key eq 'Loop';
        $Self->Is(
            $Article{$Key},
            $Test->{ArticleData}->{$Key},
            "$Test->{Name} - ArticleGet() $Key"
        );
    }
}

# cleanup is done by RestoreDatabase.

$Self->DoneTesting();
