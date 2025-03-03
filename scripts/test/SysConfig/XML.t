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

# Set up the test driver $Self when we are running as a standalone script.
use Kernel::System::UnitTest::RegisterDriver;

use vars (qw($Self));

# prevent used once warning
use Kernel::System::ObjectManager;

my $SysConfigXMLObject = $Kernel::OM->Get('Kernel::System::SysConfig::XML');
$Self->True(
    $SysConfigXMLObject,
    'Creation of Kernel::System::SysConfig::XML object must succeed.',
);

#
# SettingListParse tests
#
my @Tests = (
    {
        Description    => 'No Config',
        Config         => {},
        ExpectedResult => [],
    },
    {
        Description => 'Wrong XMLInput format',
        Config      => {
            XMLInput => { Test => 'Test' }
        },
        ExpectedResult => [],
    },
    {
        Description => 'Empty XMLInput',
        Config      => {
            XMLInput => '',
        },
        ExpectedResult => [],
    },
    {
        Description => 'Non XML XMLInput',
        Config      => {
            XMLInput => 'Test',
        },
        ExpectedResult => [],
    },
    {
        Description => 'Wrong version',
        Config      => {
            XMLInput => '<?xml version="1.0" encoding="utf-8"?>
<otobo_config version="1.0" init="Application">
    <Setting Name="Test1" Required="1" Valid="1">
        <Description Translatable="1">Test 1.</Description>
        <Navigation>Core::Ticket</Navigation>
        <Value>
            <Item ValueType="String" ValueRegex=".*">123</Item>
        </Value>
    </Setting>
    <Setting Name="Test2" Required="1" Valid="1">
        <Description Translatable="1">Test 2.</Description>
        <Navigation>Core::Ticket</Navigation>
        <Value>
            <Item ValueType="File">/usr/bin/gpg</Item>
        </Value>
    </Setting>
</otobo_config>
            ',
        },
        ExpectedResult => [],
    },
    {
        Description => 'Contains old ConfigItem(it should be ignored)',
        Config      => {
            XMLInput => '<?xml version="1.0" encoding="utf-8"?>
<otobo_config version="2.0" init="Application">
    <Setting Name="Test1" Required="1" Valid="1">
        <Description Translatable="1">Test 1.</Description>
        <Navigation>Core::Ticket</Navigation>
        <Value>
            <Item ValueType="String" ValueRegex=".*">123</Item>
        </Value>
    </Setting>
    <ConfigItem Name="Test2" Required="1" Valid="1">
        <Description Translatable="1">Test 2.</Description>
        <Group>Framework</Group>
        <SubGroup>Core</SubGroup>
        <Setting>
            <String>Test</String>
        </Setting>
    </ConfigItem>
</otobo_config>
            ',
        },
        ExpectedResult => [
            {
                'XMLContentParsed' => {
                    'Description' => [
                        {
                            'Content'      => 'Test 1.',
                            'Translatable' => '1'
                        },
                    ],
                    'Name'       => 'Test1',
                    'Navigation' => [
                        {
                            'Content' => 'Core::Ticket'
                        },
                    ],
                    'Required' => '1',
                    'Valid'    => '1',
                    'Value'    => [
                        {
                            'Item' => [
                                {
                                    'Content'    => '123',
                                    'ValueRegex' => '.*',
                                    'ValueType'  => 'String'
                                },
                            ],
                        },
                    ],
                },
                'XMLContentRaw' => '<Setting Name="Test1" Required="1" Valid="1">
        <Description Translatable="1">Test 1.</Description>
        <Navigation>Core::Ticket</Navigation>
        <Value>
            <Item ValueType="String" ValueRegex=".*">123</Item>
        </Value>
    </Setting>',

                'XMLFilename' => undef,
            },
        ],
    },
    {
        Description => 'Valid XML',
        Config      => {
            XMLInput => '<?xml version="1.0" encoding="utf-8"?>
<otobo_config version="2.0" init="Application">
    <Setting Name="Test1" Required="1" Valid="1">
        <Description Translatable="1">Test 1.</Description>
        <Navigation>Core::Ticket</Navigation>
        <Value>
            <Item ValueType="String" ValueRegex=".*">123</Item>
        </Value>
    </Setting>
    <Setting Name="Test2" Required="1" Valid="1">
        <Description Translatable="1">Test 2.</Description>
        <Navigation>Core::Ticket</Navigation>
        <Value>
            <Item ValueType="File">/usr/bin/gpg</Item>
        </Value>
    </Setting>
</otobo_config>
            ',
        },
        ExpectedResult => [
            {
                'XMLContentParsed' => {
                    'Valid'      => '1',
                    'Navigation' => [
                        {
                            'Content' => 'Core::Ticket'
                        },
                    ],
                    'Description' => [
                        {
                            'Content'      => 'Test 1.',
                            'Translatable' => '1'
                        },
                    ],
                    'Name'     => 'Test1',
                    'Required' => '1',
                    'Value'    => [
                        {
                            'Item' => [
                                {
                                    'ValueRegex' => '.*',
                                    'Content'    => '123',
                                    'ValueType'  => 'String'
                                },
                            ],
                        },
                    ],
                },
                'XMLContentRaw' => '<Setting Name="Test1" Required="1" Valid="1">
        <Description Translatable="1">Test 1.</Description>
        <Navigation>Core::Ticket</Navigation>
        <Value>
            <Item ValueType="String" ValueRegex=".*">123</Item>
        </Value>
    </Setting>',
                'XMLFilename' => undef
            },
            {
                'XMLFilename'      => undef,
                'XMLContentParsed' => {
                    'Description' => [
                        {
                            'Content'      => 'Test 2.',
                            'Translatable' => '1'
                        }
                    ],
                    'Name'       => 'Test2',
                    'Navigation' => [
                        {
                            'Content' => 'Core::Ticket'
                        },
                    ],
                    'Required' => '1',
                    'Value'    => [
                        {
                            'Item' => [
                                {
                                    'ValueType' => 'File',
                                    'Content'   => '/usr/bin/gpg'
                                },
                            ],
                        },
                    ],
                    'Valid' => '1'
                },
                'XMLContentRaw' => '<Setting Name="Test2" Required="1" Valid="1">
        <Description Translatable="1">Test 2.</Description>
        <Navigation>Core::Ticket</Navigation>
        <Value>
            <Item ValueType="File">/usr/bin/gpg</Item>
        </Value>
    </Setting>'
            }
        ],
    },
    {
        Description => 'Valid XML UTF8',
        Config      => {
            XMLInput => '<?xml version="1.0" encoding="utf-8"?>
<otobo_config version="2.0" init="Application">
    <Setting Name="äëïöüÄËÏÖÜáéíóúÁÉÍÓÚñÑ€исß" Required="1" Valid="1">
        <Description Translatable="1">Test 1.</Description>
        <Navigation>Core::Ticket</Navigation>
        <Value>
            <Item ValueType="String" ValueRegex=".*">äëïöüÄËÏÖÜáéíóúÁÉÍÓÚñÑ€исß</Item>
        </Value>
    </Setting>
    <Setting Name="Test2" Required="1" Valid="1">
        <Description Translatable="1">Test 2.</Description>
        <Navigation>Core::Ticket</Navigation>
        <Value>
            <Item ValueType="File">/usr/bin/gpg</Item>
        </Value>
    </Setting>
</otobo_config>
            ',
        },
        ExpectedResult => [
            {
                'XMLContentRaw' =>
                    '<Setting Name="äëïöüÄËÏÖÜáéíóúÁÉÍÓÚñÑ€исß" Required="1" Valid="1">
        <Description Translatable="1">Test 1.</Description>
        <Navigation>Core::Ticket</Navigation>
        <Value>
            <Item ValueType="String" ValueRegex=".*">äëïöüÄËÏÖÜáéíóúÁÉÍÓÚñÑ€исß</Item>
        </Value>
    </Setting>',
                'XMLFilename'      => undef,
                'XMLContentParsed' => {
                    'Navigation' => [
                        {
                            'Content' => 'Core::Ticket'
                        },
                    ],
                    'Description' => [
                        {
                            'Translatable' => '1',
                            'Content'      => 'Test 1.'
                        },
                    ],
                    'Required' => '1',
                    'Value'    => [
                        {
                            'Item' => [
                                {
                                    'Content' =>
                                        "\x{e4}\x{eb}\x{ef}\x{f6}\x{fc}\x{c4}\x{cb}\x{cf}\x{d6}\x{dc}\x{e1}\x{e9}\x{ed}\x{f3}\x{fa}\x{c1}\x{c9}\x{cd}\x{d3}\x{da}\x{f1}\x{d1}\x{20ac}\x{438}\x{441}\x{df}",
                                    'ValueRegex' => '.*',
                                    'ValueType'  => 'String'
                                },
                            ],
                        },
                    ],
                    'Name' =>
                        "\x{e4}\x{eb}\x{ef}\x{f6}\x{fc}\x{c4}\x{cb}\x{cf}\x{d6}\x{dc}\x{e1}\x{e9}\x{ed}\x{f3}\x{fa}\x{c1}\x{c9}\x{cd}\x{d3}\x{da}\x{f1}\x{d1}\x{20ac}\x{438}\x{441}\x{df}",
                    'Valid' => '1'
                },
            },
            {
                'XMLFilename'   => undef,
                'XMLContentRaw' => '<Setting Name="Test2" Required="1" Valid="1">
        <Description Translatable="1">Test 2.</Description>
        <Navigation>Core::Ticket</Navigation>
        <Value>
            <Item ValueType="File">/usr/bin/gpg</Item>
        </Value>
    </Setting>',
                'XMLContentParsed' => {
                    'Value' => [
                        {
                            'Item' => [
                                {
                                    'ValueType' => 'File',
                                    'Content'   => '/usr/bin/gpg'
                                },
                            ],
                        },
                    ],
                    'Valid'       => '1',
                    'Name'        => 'Test2',
                    'Description' => [
                        {
                            'Content'      => 'Test 2.',
                            'Translatable' => '1'
                        },
                    ],
                    'Navigation' => [
                        {
                            'Content' => 'Core::Ticket'
                        },
                    ],
                    'Required' => '1'
                },
            }
        ],
    },
    {
        Description => 'Invalid XML',
        Config      => {
            XMLInput => '<?xml version="1.0" encoding="utf-8"?>
<WRONG_otobo_config version="2.0" init="Application">
    <Setting Name="Test1" Required="1" Valid="1">
        <Description Translatable="1">Test 1.</Description>
        <Navigation>Core::Ticket</Navigation>
        <Value>
            <Item ValueType="String" ValueRegex=".*">123</Item>
        </Value>
    </Setting>
    <Setting Name="Test2" Required="1" Valid="1">
        <Description Translatable="1">Test 2.</Description>
        <Navigation>Core::Ticket</Navigation>
        <Value>
            <Item ValueType="File">/usr/bin/gpg</Item>
        </Value>
    </Setting>
</otobo_config>
            ',
        },
        ExpectedResult => [
            {
                'XMLFilename'      => undef,
                'XMLContentParsed' => {
                    'Name'        => 'Test1',
                    'Required'    => '1',
                    'Description' => [
                        {
                            'Translatable' => '1',
                            'Content'      => 'Test 1.'
                        },
                    ],
                    'Valid' => '1',
                    'Value' => [
                        {
                            'Item' => [
                                {
                                    'Content'    => '123',
                                    'ValueType'  => 'String',
                                    'ValueRegex' => '.*'
                                },
                            ],
                        },
                    ],
                    'Navigation' => [
                        {
                            'Content' => 'Core::Ticket'
                        },
                    ],
                },
                'XMLContentRaw' => '<Setting Name="Test1" Required="1" Valid="1">
        <Description Translatable="1">Test 1.</Description>
        <Navigation>Core::Ticket</Navigation>
        <Value>
            <Item ValueType="String" ValueRegex=".*">123</Item>
        </Value>
    </Setting>'
            },
            {
                'XMLContentParsed' => {
                    'Description' => [
                        {
                            'Content'      => 'Test 2.',
                            'Translatable' => '1'
                        },
                    ],
                    'Name'       => 'Test2',
                    'Required'   => '1',
                    'Navigation' => [
                        {
                            'Content' => 'Core::Ticket'
                        },
                    ],
                    'Value' => [
                        {
                            'Item' => [
                                {
                                    'ValueType' => 'File',
                                    'Content'   => '/usr/bin/gpg'
                                },
                            ],
                        },
                    ],
                    'Valid' => '1'
                },
                'XMLContentRaw' => '<Setting Name="Test2" Required="1" Valid="1">
        <Description Translatable="1">Test 2.</Description>
        <Navigation>Core::Ticket</Navigation>
        <Value>
            <Item ValueType="File">/usr/bin/gpg</Item>
        </Value>
    </Setting>',
                'XMLFilename' => undef
            }
        ],
    },
    {
        Description => 'Missing surrounding otobo_config element',
        Config      => {
            XMLInput => '<?xml version="1.0" encoding="utf-8"?>
<Setting Name="Test1" Required="1" Valid="1">
    <Description Translatable="1">Test 1.</Description>
    <Navigation>Core::Ticket</Navigation>
    <Value>
        <Item ValueType="String" ValueRegex=".*">123</Item>
    </Value>
</Setting>
<Setting Name="Test2" Required="1" Valid="1">
    <Description Translatable="1">Test 2.</Description>
    <Navigation>Core::Ticket</Navigation>
    <Value>
        <Item ValueType="File">/usr/bin/gpg</Item>
    </Value>
</Setting>
            ',
        },
        ExpectedResult => [],
    },
    {
        Description => 'No Setting elements',
        Config      => {
            XMLInput => '<?xml version="1.0" encoding="utf-8"?>
<otobo_config version="2.0" init="Application">
    <NoSetting Name="Test1" Required="1" Valid="1">
        <Description Translatable="1">Test 1.</Description>
        <Navigation>Core::Ticket</Navigation>
        <Value>
            <Item ValueType="String" ValueRegex=".*">123</Item>
        </Value>
    </NoSetting>
    <NoSetting Name="Test2" Required="1" Valid="1">
        <Description Translatable="1">Test 2.</Description>
        <Navigation>Core::Ticket</Navigation>
        <Value>
            <Item ValueType="File">/usr/bin/gpg</Item>
        </Value>
    </NoSetting>
</otobo_config>
            ',
        },
        ExpectedResult => [],
    },
    {
        Description => 'Setting without Name attribute',
        Config      => {
            XMLInput => '<?xml version="1.0" encoding="utf-8"?>
<otobo_config version="2.0" init="Application">
    <Setting Required="1" Valid="1">
        <Description Translatable="1">Test 1.</Description>
        <Navigation>Core::Ticket</Navigation>
        <Value>
            <Item ValueType="String" ValueRegex=".*">123</Item>
        </Value>
    </Setting>
    <Setting Name="Test2" Required="1" Valid="1">
        <Description Translatable="1">Test 2.</Description>
        <Navigation>Core::Ticket</Navigation>
        <Value>
            <Item ValueType="File">/usr/bin/gpg</Item>
        </Value>
    </Setting>
</otobo_config>
            ',
        },
        ExpectedResult => [],
    },
    {
        Description => 'Setting with comments',
        Config      => {
            XMLInput => '<?xml version="1.0" encoding="utf-8"?>
<otobo_config version="2.0" init="Application">
    <Setting Name="Test" Required="1" Valid="1">
        <Description Translatable="1">Test 1.</Description>
        <Navigation>Core::Ticket</Navigation>
        <Value>
            <Array>
                <Item>1</Item>
#               <Item>2</Item>
<!--
                <Item>2</Item>
                <Item>2</Item>
-->
                <Item>2</Item>
            </Array>
        </Value>
    </Setting>
</otobo_config>
            ',
        },
        ExpectedResult => [
            {
                'XMLContentParsed' => {
                    'Description' => [
                        {
                            'Content'      => 'Test 1.',
                            'Translatable' => '1',
                        },
                    ],
                    'Name'       => 'Test',
                    'Navigation' => [
                        {
                            'Content' => 'Core::Ticket'
                        },
                    ],
                    'Required' => '1',
                    'Valid'    => '1',
                    'Value'    => [
                        {
                            'Array' => [
                                {
                                    'Item' => [
                                        {
                                            'Content' => '1',
                                        },
                                        {
                                            'Content' => '2',
                                        },
                                    ],
                                },
                            ],
                        },
                    ],
                },
                'XMLContentRaw' => '<Setting Name="Test" Required="1" Valid="1">
        <Description Translatable="1">Test 1.</Description>
        <Navigation>Core::Ticket</Navigation>
        <Value>
            <Array>
                <Item>1</Item>


                <Item>2</Item>
            </Array>
        </Value>
    </Setting>',
            },
        ],
    },
);

for my $Test (@Tests) {

    my @Result = $SysConfigXMLObject->SettingListParse( %{ $Test->{Config} } );

    $Self->IsDeeply(
        \@Result,
        $Test->{ExpectedResult},
        $Test->{Description} . ': SettingLisParse(): Result must match expected one.',
    );
}

$Self->DoneTesting();
