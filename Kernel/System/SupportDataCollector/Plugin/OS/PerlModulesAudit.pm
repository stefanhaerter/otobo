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

package Kernel::System::SupportDataCollector::Plugin::OS::PerlModulesAudit;

use strict;
use warnings;

use parent qw(Kernel::System::SupportDataCollector::PluginBase);

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::System::Console::Command::Dev::Code::CPANAudit',
    'Kernel::System::Log',
);

sub GetDisplayPath {
    return Translatable('Operating System');
}

sub Run {
    my $Self = shift;

    my $CommandObject = $Kernel::OM->Get('Kernel::System::Console::Command::Dev::Code::CPANAudit');

    my ( $CommandOutput, $ExitCode );

    {
        local *STDOUT;
        open STDOUT, '>:utf8', \$CommandOutput;    ## no critic qw(OTOBO::ProhibitOpen InputOutput::RequireEncodingWithUTF8Layer)
        $ExitCode = $CommandObject->Execute();
    }

    if ( $ExitCode != 0 ) {
        $Self->AddResultWarning(
            Label   => Translatable('Perl Modules Audit'),
            Value   => $CommandOutput,
            Message => Translatable(
                'CPAN::Audit reported that one or more installed Perl modules have known vulnerabilities. Please note that there might be false positives for distributions patching Perl modules without changing their version number.'
            ),
        );
    }
    else {
        $Self->AddResultOk(
            Label   => Translatable('Perl Modules Audit'),
            Value   => '',
            Message =>
                Translatable('CPAN::Audit did not report any known vulnerabilities in the installed Perl modules.'),
        );
    }

    return $Self->GetResults();
}

1;
