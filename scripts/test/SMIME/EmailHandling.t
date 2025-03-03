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
use Test2::V0;
use Kernel::System::UnitTest::RegisterDriver;

our $Self;

use File::Path qw(mkpath rmtree);

use Kernel::Output::HTML::ArticleCheck::SMIME;

# get needed objects
my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
my $MainObject      = $Kernel::OM->Get('Kernel::System::Main');
my $TicketObject    = $Kernel::OM->Get('Kernel::System::Ticket');
my $ArticleObject   = $Kernel::OM->Get('Kernel::System::Ticket::Article');
my $HTMLUtilsObject = $Kernel::OM->Get('Kernel::System::HTMLUtils');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);
my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# Disable email addresses checking.
$Helper->ConfigSettingChange(
    Key   => 'CheckEmailAddresses',
    Value => 0,
);

my $HomeDir = $ConfigObject->Get('Home');

# create directory for certificates and private keys
my $CertPath    = $ConfigObject->Get('Home') . "/var/tmp/certs";
my $PrivatePath = $ConfigObject->Get('Home') . "/var/tmp/private";
mkpath( [$CertPath],    0, 0770 );    ## no critic qw(ValuesAndExpressions::ProhibitLeadingZeros)
mkpath( [$PrivatePath], 0, 0770 );    ## no critic qw(ValuesAndExpressions::ProhibitLeadingZeros)

# set SMIME paths
$ConfigObject->Set(
    Key   => 'SMIME::CertPath',
    Value => $CertPath,
);
$ConfigObject->Set(
    Key   => 'SMIME::PrivatePath',
    Value => $PrivatePath,
);

my $OpenSSLBin = $ConfigObject->Get('SMIME::Bin') || '/usr/bin/openssl';

# get the openssl version string, e.g. OpenSSL 0.9.8e 23 Feb 2007
my $OpenSSLVersionString = qx{$OpenSSLBin version};
my $OpenSSLMajorVersion;

# get the openssl major version, e.g. 1 for version 1.0.0
if ( $OpenSSLVersionString =~ m{ \A (?: (?: Open|Libre)SSL )? \s* ( \d )  }xmsi ) {
    $OpenSSLMajorVersion = $1;
}

# openssl version 1.0.0 uses different hash algorithm... in the future release of openssl this might
#change again in such case a better version detection will be needed
my $UseNewHashes;
if ( $OpenSSLMajorVersion >= 1 ) {
    $UseNewHashes = 1;
}

# set config
$ConfigObject->Set(
    Key   => 'SMIME',
    Value => 1,
);
$ConfigObject->Set(
    Key   => 'SendmailModule',
    Value => 'Kernel::System::Email::DoNotSendEmail',
);

# check if openssl is located there
if ( !-e $OpenSSLBin ) {

    # maybe it's a mac with macport
    if ( -e '/opt/local/bin/openssl' ) {
        $ConfigObject->Set(
            Key   => 'SMIME::Bin',
            Value => '/opt/local/bin/openssl',
        );
    }
}

# create crypt object
my $SMIMEObject = $Kernel::OM->Get('Kernel::System::Crypt::SMIME');

if ( !$SMIMEObject ) {
    print STDERR "NOTICE: No SMIME support!\n";

    if ( !-e $OpenSSLBin ) {
        $Self->False(
            1,
            "No such $OpenSSLBin!",
        );
    }
    elsif ( !-x $OpenSSLBin ) {
        $Self->False(
            1,
            "$OpenSSLBin not executable!",
        );
    }
    elsif ( !-e $CertPath ) {
        $Self->False(
            1,
            "No such $CertPath!",
        );
    }
    elsif ( !-d $CertPath ) {
        $Self->False(
            1,
            "No such $CertPath directory!",
        );
    }
    elsif ( !-w $CertPath ) {
        $Self->False(
            1,
            "$CertPath not writable!",
        );
    }
    elsif ( !-e $PrivatePath ) {
        $Self->False(
            1,
            "No such $PrivatePath!",
        );
    }
    elsif ( !-d $Self->{PrivatePath} ) {
        $Self->False(
            1,
            "No such $PrivatePath directory!",
        );
    }
    elsif ( !-w $PrivatePath ) {
        $Self->False(
            1,
            "$PrivatePath not writable!",
        );
    }

    done_testing();

    exit 0;
}

#
# Setup environment
#

# OpenSSL 0.9.x hashes
my $Check1Hash        = '980a83c7';
my $Check2Hash        = '999bcb2f';
my $OTOBORootCAHash   = '1a01713f';
my $OTOBORDCAHash     = '7807c24e';
my $OTOBOLabCAHash    = '2fc24258';
my $OTOBOUserCertHash = 'eab039b6';

# OpenSSL 1.0.0 hashes
if ($UseNewHashes) {
    $Check1Hash        = 'f62a2257';
    $Check2Hash        = '35c7d865';
    $OTOBORootCAHash   = '7835cf94';
    $OTOBORDCAHash     = 'b5d19fb9';
    $OTOBOLabCAHash    = '19545811';
    $OTOBOUserCertHash = '4d400195';
}

# certificates
my @Certificates = (
    {
        CertificateName       => 'Check1',
        CertificateHash       => $Check1Hash,
        CertificateFileName   => 'SMIMECertificate-1.asc',
        PrivateKeyFileName    => 'SMIMEPrivateKey-1.asc',
        PrivateSecretFileName => 'SMIMEPrivateKeyPass-1.asc',
    },
    {
        CertificateName       => 'Check2',
        CertificateHash       => $Check2Hash,
        CertificateFileName   => 'SMIMECertificate-2.asc',
        PrivateKeyFileName    => 'SMIMEPrivateKey-2.asc',
        PrivateSecretFileName => 'SMIMEPrivateKeyPass-2.asc',
    },
    {
        CertificateName       => 'OTOBOUserCert',
        CertificateHash       => $OTOBOUserCertHash,
        CertificateFileName   => 'SMIMECertificate-smimeuser1.crt',
        PrivateKeyFileName    => 'SMIMEPrivateKey-smimeuser1.pem',
        PrivateSecretFileName => 'SMIMEPrivateKeyPass-smimeuser1.crt',
    },
    {
        CertificateName       => 'OTOBOLabCA',
        CertificateHash       => $OTOBOLabCAHash,
        CertificateFileName   => 'SMIMECACertificate-OTOBOLab.crt',
        PrivateKeyFileName    => 'SMIMECAPrivateKey-OTOBOLab.pem',
        PrivateSecretFileName => 'SMIMECAPrivateKeyPass-OTOBOLab.crt',
    },
    {
        CertificateName       => 'OTOBORDCA',
        CertificateHash       => $OTOBORDCAHash,
        CertificateFileName   => 'SMIMECACertificate-OTOBORD.crt',
        PrivateKeyFileName    => 'SMIMECAPrivateKey-OTOBORD.pem',
        PrivateSecretFileName => 'SMIMECAPrivateKeyPass-OTOBORD.crt',
    },
    {
        CertificateName       => 'OTOBORootCA',
        CertificateHash       => $OTOBORootCAHash,
        CertificateFileName   => 'SMIMECACertificate-OTOBORoot.crt',
        PrivateKeyFileName    => 'SMIMECAPrivateKey-OTOBORoot.pem',
        PrivateSecretFileName => 'SMIMECAPrivateKeyPass-OTOBORoot.crt',
    },
);

# add chain certificates
for my $Certificate (@Certificates) {

    # add certificate ...
    my $CertString = $MainObject->FileRead(
        Directory => $ConfigObject->Get('Home') . "/scripts/test/sample/SMIME/",
        Filename  => $Certificate->{CertificateFileName},
    );
    my %Result = $SMIMEObject->CertificateAdd( Certificate => ${$CertString} );
    $Self->True(
        $Result{Successful} || '',
        "#$Certificate->{CertificateName} CertificateAdd() - $Result{Message}",
    );

    # add private key
    my $KeyString = $MainObject->FileRead(
        Directory => $ConfigObject->Get('Home') . "/scripts/test/sample/SMIME/",
        Filename  => $Certificate->{PrivateKeyFileName},
    );
    my $Secret = $MainObject->FileRead(
        Directory => $ConfigObject->Get('Home') . "/scripts/test/sample/SMIME/",
        Filename  => $Certificate->{PrivateSecretFileName},
    );
    %Result = $SMIMEObject->PrivateAdd(
        Private => ${$KeyString},
        Secret  => ${$Secret},
    );
    $Self->True(
        $Result{Successful} || '',
        "#$Certificate->{CertificateName} PrivateAdd()",
    );
}

my $TicketID = $TicketObject->TicketCreate(
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

#
# actual tests
#

# different mails to test
my @Tests = (
    {
        Name        => 'simple string',
        ArticleData => {
            Body     => 'Simple string',
            MimeType => 'text/plain',
        },
    },
    {
        Name        => 'simple string with unix newline',
        ArticleData => {
            Body     => 'Simple string \n with unix newline',
            MimeType => 'text/plain',
        },
    },
    {
        Name        => 'simple string with windows newline',
        ArticleData => {
            Body     => 'Simple string \r\n with windows newline',
            MimeType => 'text/plain',
        },
    },
    {
        Name        => 'simple string with long word',
        ArticleData => {
            Body =>
                'SimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleStringSimpleString',
            MimeType => 'text/plain',
        },
    },
    {
        Name        => 'simple string with long lines',
        ArticleData => {
            Body =>
                'Simple string Simple string Simple string Simple string Simple string Simple string Simple string Simple string Simple string Simple string Simple string Simple string Simple string Simple string Simple string Simple string',
            MimeType => 'text/plain',
        },
    },
    {
        Name        => 'simple string with unicode data',
        ArticleData => {
            Body     => 'äöüßø@«∑€©ƒ',
            MimeType => 'text/plain',
        },
    },
    {
        Name        => 'Multiline HTML',
        ArticleData => {
            Body =>
                '<!DOCTYPE html><html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"/></head><body style="font-family:Geneva,Helvetica,Arial,sans-serif; font-size: 12px;">Simple Line<br/><br/><br/>Your Ticket-Team<br/><br/>Your Agent<br/><br/>--<br/> Super Support - Waterford Business Park<br/> 5201 Blue Lagoon Drive - 8th Floor &amp; 9th Floor - Miami, 33126 USA<br/> Email: hot@example.com - Web: <a href="http://www.example.com/" title="http://www.example.com/" target="_blank">http://www.example.com/</a><br/>--</body></html>',
            MimeType => 'text/html',
        },
    },
    {
        Name        => 'Inline Attachment',
        ArticleData => {
            Body =>
                '<!DOCTYPE html><html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"/></head><body style="font-family:Geneva,Helvetica,Arial,sans-serif; font-size: 12px;">Hi<img alt="" src="cid:inline835421.188799263.1394842906.6253839.53368344@Mandalore.local" style="height:16px; width:16px" /></body></html>',
            MimeType   => 'text/html',
            Attachment => [
                {
                    ContentID =>
                        'inline835421.188799263.1394842906.6253839.53368344@Mandalore.local',
                    Content     => 'Any',
                    ContentType => 'image/png; name="ui-toolbar-bookmark.png"',
                    Filename    => 'ui-toolbar-bookmark.png',
                    Disposition => 'inline',
                },
            ],
        },
    },
    {
        Name        => 'Normal Attachment',
        ArticleData => {
            Body =>
                '<!DOCTYPE html><html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"/></head><body style="font-family:Geneva,Helvetica,Arial,sans-serif; font-size: 12px;">Simple Line<br/><br/><br/>Your Ticket-Team<br/><br/>Your Agent<br/><br/>--<br/> Super Support - Waterford Business Park<br/> 5201 Blue Lagoon Drive - 8th Floor &amp; 9th Floor - Miami, 33126 USA<br/> Email: hot@example.com - Web: <a href="http://www.example.com/" title="http://www.example.com/" target="_blank">http://www.example.com/</a><br/>--</body></html>',
            MimeType   => 'text/html',
            Attachment => [
                {
                    ContentID   => '',
                    Content     => 'Any',
                    ContentType => 'image/png; name="ui-toolbar-bookmark.png"',
                    Filename    => 'ui-toolbar-bookmark.png',
                    Disposition => 'attachment',
                },
            ],
        },
    },
);

# test each mail with sign/crypt/sign+crypt
my @TestVariations;

for my $Test (@Tests) {
    push @TestVariations, {
        %{$Test},
        Name        => $Test->{Name} . " (old API) sign only",
        ArticleData => {
            %{ $Test->{ArticleData} },
            From => 'unittest@example.org',
            To   => 'unittest@example.org',
            Sign => {
                Type    => 'SMIME',
                SubType => 'Detached',
                Key     => $Check1Hash . '.0',
            },
        },
        VerifySignature  => 1,
        VerifyDecryption => 0,
    };

    push @TestVariations, {
        %{$Test},
        Name        => $Test->{Name} . " (old API) crypt only",
        ArticleData => {
            %{ $Test->{ArticleData} },
            From  => 'unittest@example.org',
            To    => 'unittest@example.org',
            Crypt => {
                Type => 'SMIME',
                Key  => $Check1Hash . '.0',
            },
        },
        VerifySignature  => 0,
        VerifyDecryption => 1,
    };

    push @TestVariations, {
        %{$Test},
        Name        => $Test->{Name} . " (old API) sign and crypt",
        ArticleData => {
            %{ $Test->{ArticleData} },
            From => 'unittest@example.org',
            To   => 'unittest@example.org',
            Sign => {
                Type    => 'SMIME',
                SubType => 'Detached',
                Key     => $Check1Hash . '.0',
            },
            Crypt => {
                Type => 'SMIME',
                Key  => $Check1Hash . '.0',
            },
        },
        VerifySignature  => 1,
        VerifyDecryption => 1,
    };

    push @TestVariations, {
        %{$Test},
        Name        => $Test->{Name} . " (old API) chain CA cert sign only",
        ArticleData => {
            %{ $Test->{ArticleData} },
            From => 'smimeuser1@test.com',
            To   => 'smimeuser1@test.com',
            Sign => {
                Type    => 'SMIME',
                SubType => 'Detached',
                Key     => $OTOBOUserCertHash . '.0',
            },
        },
        VerifySignature  => 1,
        VerifyDecryption => 0,
    };

    push @TestVariations, {
        %{$Test},
        Name        => $Test->{Name} . " (old API) chain CA cert crypt only",
        ArticleData => {
            %{ $Test->{ArticleData} },
            From  => 'smimeuser1@test.com',
            To    => 'smimeuser1@test.com',
            Crypt => {
                Type => 'SMIME',
                Key  => $OTOBOUserCertHash . '.0',
            },
        },
        VerifySignature  => 0,
        VerifyDecryption => 1,
    };

    push @TestVariations, {
        %{$Test},
        Name        => $Test->{Name} . " (old API) chain CA cert sign and crypt",
        ArticleData => {
            %{ $Test->{ArticleData} },
            From => 'smimeuser1@test.com',
            To   => 'smimeuser1@test.com',
            Sign => {
                Type    => 'SMIME',
                SubType => 'Detached',
                Key     => $OTOBOUserCertHash . '.0',
            },
            Crypt => {
                Type => 'SMIME',
                Key  => $OTOBOUserCertHash . '.0',
            },
        },
        VerifySignature  => 1,
        VerifyDecryption => 1,
    };

    # here starts the tests for new API

    push @TestVariations, {
        %{$Test},
        Name        => $Test->{Name} . " sign only",
        ArticleData => {
            %{ $Test->{ArticleData} },
            From          => 'unittest@example.org',
            To            => 'unittest@example.org',
            EmailSecurity => {
                Backend => 'SMIME',
                Method  => 'Detached',
                SignKey => $Check1Hash . '.0',
            },
        },
        VerifySignature  => 1,
        VerifyDecryption => 0,
    };

    push @TestVariations, {
        %{$Test},
        Name        => $Test->{Name} . " crypt only",
        ArticleData => {
            %{ $Test->{ArticleData} },
            From          => 'unittest@example.org',
            To            => 'unittest@example.org',
            EmailSecurity => {
                Backend     => 'SMIME',
                Method      => 'Detached',
                EncryptKeys => [ $Check1Hash . '.0', $OTOBOUserCertHash . '.0' ],
            },
        },
        VerifySignature  => 0,
        VerifyDecryption => 1,
    };

    push @TestVariations, {
        %{$Test},
        Name        => $Test->{Name} . " crypt only (multiple recipients)",
        ArticleData => {
            %{ $Test->{ArticleData} },
            From          => 'unittest@example.org',
            To            => 'unittest@example.org, smimeuser1@test.com',
            EmailSecurity => {
                Backend     => 'SMIME',
                Method      => 'Detached',
                EncryptKeys => [ $Check1Hash . '.0' ],
            },
        },
        VerifySignature  => 0,
        VerifyDecryption => 1,
    };

    push @TestVariations, {
        %{$Test},
        Name        => $Test->{Name} . " sign and crypt",
        ArticleData => {
            %{ $Test->{ArticleData} },
            From          => 'unittest@example.org',
            To            => 'unittest@example.org',
            EmailSecurity => {
                Backend     => 'SMIME',
                SubType     => 'Detached',
                SignKey     => $Check1Hash . '.0',
                EncryptKeys => [ $Check1Hash . '.0' ],
            },
        },
        VerifySignature  => 1,
        VerifyDecryption => 1,
    };

    push @TestVariations, {
        %{$Test},
        Name        => $Test->{Name} . " chain CA cert sign only",
        ArticleData => {
            %{ $Test->{ArticleData} },
            From          => 'smimeuser1@test.com',
            To            => 'smimeuser1@test.com',
            EmailSecurity => {
                Backend => 'SMIME',
                SubType => 'Detached',
                SignKey => $OTOBOUserCertHash . '.0',
            },
        },
        VerifySignature  => 1,
        VerifyDecryption => 0,
    };

    push @TestVariations, {
        %{$Test},
        Name        => $Test->{Name} . " chain CA cert crypt only",
        ArticleData => {
            %{ $Test->{ArticleData} },
            From          => 'smimeuser1@test.com',
            To            => 'smimeuser1@test.com',
            EmailSecurity => {
                Backend     => 'SMIME',
                EncryptKeys => [ $OTOBOUserCertHash . '.0' ],
            },
        },
        VerifySignature  => 0,
        VerifyDecryption => 1,
    };

    push @TestVariations, {
        %{$Test},
        Name        => $Test->{Name} . " chain CA cert sign and crypt",
        ArticleData => {
            %{ $Test->{ArticleData} },
            From          => 'smimeuser1@test.com',
            To            => 'smimeuser1@test.com',
            EmailSecurity => {
                Backend     => 'SMIME',
                SubType     => 'Detached',
                SignKey     => $OTOBOUserCertHash . '.0',
                EncryptKeys => [ $OTOBOUserCertHash . '.0' ],
            },
        },
        VerifySignature  => 1,
        VerifyDecryption => 1,
    };

}
my $MailQueueObj = $Kernel::OM->Get('Kernel::System::MailQueue');
for my $Test (@TestVariations) {

    # make a deep copy as the references gets modified over the tests
    $Test = Storable::dclone($Test);

    my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Email' );

    my $ArticleID = $ArticleBackendObject->ArticleSend(
        TicketID             => $TicketID,
        From                 => $Test->{ArticleData}->{From},
        To                   => $Test->{ArticleData}->{To},
        IsVisibleForCustomer => 1,
        SenderType           => 'customer',
        HistoryType          => 'AddNote',
        HistoryComment       => 'note',
        Subject              => 'Unittest data',
        Charset              => 'utf-8',
        MimeType             => $Test->{ArticleData}->{MimeType},    # "text/plain" or "text/html"
        Body                 => 'Some nice text\n.',
        Sign                 => {
            Type    => 'SMIME',
            SubType => 'Detached',
            Key     => $Test->{ArticleData}->{Sign}->{Key},
        },
        UserID => 1,
        %{ $Test->{ArticleData} },
    );

    $Self->True(
        $ArticleID,
        "$Test->{Name} - ArticleSend()",
    );

    my %Article = $ArticleBackendObject->ArticleGet(
        TicketID  => $TicketID,
        ArticleID => $ArticleID,
    );

    my $CheckObject = Kernel::Output::HTML::ArticleCheck::SMIME->new(
        ArticleID => $ArticleID,
        UserID    => 1,
    );

    my $Item = $MailQueueObj->Get( ArticleID => $ArticleID );

    my $Result = $MailQueueObj->Send( %{$Item} );

    my @CheckResult = $CheckObject->Check( Article => \%Article );

    # Run check a second time to simulate repeated views.
    my @FirstCheckResult = @CheckResult;
    @CheckResult = $CheckObject->Check( Article => \%Article );

    $Self->IsDeeply(
        \@FirstCheckResult,
        \@CheckResult,
        "$Test->{Name} - CheckObject() stable",
    );

    if ( $Test->{VerifySignature} ) {
        my $SignatureVerified =
            grep {
                $_->{Successful} && $_->{Key} eq 'Signed' && $_->{SignatureFound} && $_->{Message}
            } @CheckResult;

        $Self->True(
            $SignatureVerified,
            "$Test->{Name} - signature verified",
        );
    }

    if ( $Test->{VerifyDecryption} ) {
        my $DecryptionVerified =
            grep { $_->{Successful} && $_->{Key} eq 'Crypted' && $_->{Message} } @CheckResult;

        $Self->True(
            $DecryptionVerified,
            "$Test->{Name} - decryption verified",
        );
    }

    my %FinalArticleData = $ArticleBackendObject->ArticleGet(
        TicketID  => $TicketID,
        ArticleID => $ArticleID,
    );

    my $TestBody = $Test->{ArticleData}->{Body};

    # convert test body to ASCII if it was HTML
    if ( $Test->{ArticleData}->{MimeType} eq 'text/html' ) {
        $TestBody = $HTMLUtilsObject->ToAscii(
            String => $TestBody,
        );
    }

    $Self->Is(
        $FinalArticleData{Body},
        $TestBody,
        "$Test->{Name} - verified body content",
    );

    if ( defined $Test->{ArticleData}->{Attachment} ) {
        my $Found;
        my %Index = $ArticleBackendObject->ArticleAttachmentIndex(
            ArticleID => $ArticleID,
        );

        TESTATTACHMENT:
        for my $Attachment ( @{ $Test->{ArticleData}->{Attachment} } ) {

            next TESTATTACHMENT if !$Attachment->{Filename};

            ATTACHMENTINDEX:
            for my $AttachmentIndex ( sort keys %Index ) {

                if ( $Index{$AttachmentIndex}->{Filename} ne $Attachment->{Filename} ) {
                    next ATTACHMENTINDEX;
                }
                my $ExpectedContentID = $Attachment->{ContentID};
                if ( $Attachment->{ContentID} ) {
                    $ExpectedContentID = '<' . $Attachment->{ContentID} . '>';
                }
                $Self->Is(
                    $Index{$AttachmentIndex}->{ContentID},
                    $ExpectedContentID,
                    "$Test->{Name} - Attachment '$Attachment->{Filename}' ContentID",
                );
                $Found = 1;
                last ATTACHMENTINDEX;
            }
            $Self->True(
                $Found,
                "$Test->{Name} - Attachment '$Attachment->{Filename}' was found"
            );
        }

        # Remove all attachments, then run CheckObject again to verify they are not written again.
        $ArticleBackendObject->ArticleDeleteAttachment(
            ArticleID => $ArticleID,
            UserID    => 1,
        );

        $CheckObject->Check( Article => \%Article );

        %Index = $ArticleBackendObject->ArticleAttachmentIndex(
            ArticleID => $ArticleID,
        );
        $Self->False(
            scalar keys %Index,
            "$Test->{Name} - Attachments not rewritten by ArticleCheck module"
        );
    }
}

# delete needed test directories
for my $Directory ( $CertPath, $PrivatePath ) {
    my $Success = rmtree( [$Directory] );
    $Self->True(
        $Success,
        "Directory deleted - '$Directory'",
    );
}

# cleanup is done by RestoreDatabase.

$Self->DoneTesting();
