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

my $DFBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

my $UserID = 1;

# Theres is not really needed to add the dynamic fields for this test, we can define a static
# set of configurations.
my %DynamicFieldConfigs = (
    Text => {
        ID            => 123,
        InternalField => 0,
        Name          => 'TextField',
        Label         => 'TextField',
        FieldOrder    => 123,
        FieldType     => 'Text',
        ObjectType    => 'Ticket',
        Config        => {
            DefaultValue => '',
            Link         => '',
        },
        ValidID    => 1,
        CreateTime => '2011-02-08 15:08:00',
        ChangeTime => '2011-06-11 17:22:00',
    },
    TextArea => {
        ID            => 123,
        InternalField => 0,
        Name          => 'TextAreaField',
        Label         => 'TextAreaField',
        FieldOrder    => 123,
        FieldType     => 'TextArea',
        ObjectType    => 'Ticket',
        Config        => {
            DefaultValue => '',
            Rows         => '',
            Cols         => '',
        },
        ValidID    => 1,
        CreateTime => '2011-02-08 15:08:00',
        ChangeTime => '2011-06-11 17:22:00',
    },
    Checkbox => {
        ID            => 123,
        InternalField => 0,
        Name          => 'CheckboxField',
        Label         => 'CheckboxField',
        FieldOrder    => 123,
        FieldType     => 'Checkbox',
        ObjectType    => 'Ticket',
        Config        => {
            DefaultValue => '',
        },
        ValidID    => 1,
        CreateTime => '2011-02-08 15:08:00',
        ChangeTime => '2011-06-11 17:22:00',
    },
    Dropdown => {
        ID            => 123,
        InternalField => 0,
        Name          => 'DropdownField',
        Label         => 'DropdownField',
        FieldOrder    => 123,
        FieldType     => 'Dropdown',
        ObjectType    => 'Ticket',
        Config        => {
            DefaultValue       => '',
            Link               => '',
            PossibleNone       => 1,
            TranslatableValues => 1,
            PossibleValues     => {
                1 => 'A',
                2 => 'B',
            },
        },
        ValidID    => 1,
        CreateTime => '2011-02-08 15:08:00',
        ChangeTime => '2011-06-11 17:22:00',
    },
    Multiselect => {
        ID            => 123,
        InternalField => 0,
        Name          => 'MultiselectField',
        Label         => 'MultiselectField',
        FieldOrder    => 123,
        FieldType     => 'Multiselect',
        ObjectType    => 'Ticket',
        Config        => {
            DefaultValue       => '',
            PossibleNone       => 1,
            TranslatableValues => 1,
            PossibleValues     => {
                1 => 'A',
                2 => 'B',
            },
        },
        ValidID    => 1,
        CreateTime => '2011-02-08 15:08:00',
        ChangeTime => '2011-06-11 17:22:00',
    },
    DateTime => {
        ID            => 123,
        InternalField => 0,
        Name          => 'DateTimeField',
        Label         => 'DateTimeField',
        FieldOrder    => 123,
        FieldType     => 'DateTime',
        ObjectType    => 'Ticket',
        Config        => {
            DefaultValue  => '',
            Link          => '',
            YearsPeriod   => '',
            YearsInFuture => '',
            YearsInPast   => '',
        },
        ValidID    => 1,
        CreateTime => '2011-02-08 15:08:00',
        ChangeTime => '2011-06-11 17:22:00',
    },
    Date => {
        ID            => 123,
        InternalField => 0,
        Name          => 'DateField',
        Label         => 'DateField',
        FieldOrder    => 123,
        FieldType     => 'Date',
        ObjectType    => 'Ticket',
        Config        => {
            DefaultValue  => '',
            Link          => '',
            YearsPeriod   => '',
            YearsInFuture => '',
            YearsInPast   => '',
        },
        ValidID    => 1,
        CreateTime => '2011-02-08 15:08:00',
        ChangeTime => '2011-06-11 17:22:00',
    },
);

# define tests
my @Tests = (

    # text dynamic field
    {
        Name   => 'Text DynamicField',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Text},
        },
        ExpectedResults => {
            Name    => $DynamicFieldConfigs{Text}->{Label},
            Element => 'DynamicField_' . $DynamicFieldConfigs{Text}->{Name},
            Block   => 'InputField',
        },
    },
    {
        Name   => 'TextArea DynamicField',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{TextArea},
        },
        ExpectedResults => {
            Name    => $DynamicFieldConfigs{TextArea}->{Label},
            Element => 'DynamicField_' . $DynamicFieldConfigs{TextArea}->{Name},
            Block   => 'InputField',
        },
    },
    {
        Name   => 'Checkbox DynamicField',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Checkbox},
        },
        ExpectedResults => {
            Values => {
                '1'  => 'Checked',
                '-1' => 'Unchecked',
            },
            Name               => $DynamicFieldConfigs{Checkbox}->{Label},
            Element            => 'DynamicField_' . $DynamicFieldConfigs{Checkbox}->{Name},
            TranslatableValues => 1,
        },
    },
    {
        Name   => 'Dropdown DynamicField',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Dropdown},
        },
        ExpectedResults => {
            Values             => $DynamicFieldConfigs{Dropdown}->{Config}->{PossibleValues},
            Name               => $DynamicFieldConfigs{Dropdown}->{Label},
            Element            => 'DynamicField_' . $DynamicFieldConfigs{Dropdown}->{Name},
            TranslatableValues => $DynamicFieldConfigs{Dropdown}->{Config}->{TranslatableValues},
            Block              => 'MultiSelectField',
        },
    },
    {
        Name   => 'Multiselect DynamicField',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Multiselect},
        },
        ExpectedResults => {
            Values             => $DynamicFieldConfigs{Multiselect}->{Config}->{PossibleValues},
            Name               => $DynamicFieldConfigs{Multiselect}->{Label},
            Element            => 'DynamicField_' . $DynamicFieldConfigs{Multiselect}->{Name},
            TranslatableValues => $DynamicFieldConfigs{Multiselect}->{Config}->{TranslatableValues},
            Block              => 'MultiSelectField',
        },
    },
    {
        Name   => 'DateTime DynamicField',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{DateTime},
        },
        ExpectedResults => {
            Name             => $DynamicFieldConfigs{DateTime}->{Label},
            Element          => 'DynamicField_' . $DynamicFieldConfigs{DateTime}->{Name},
            TimePeriodFormat => 'DateInputFormatLong',
            Block            => 'Time',
        },
    },
    {
        Name   => 'Date DynamicField',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Date},
        },
        ExpectedResults => {
            Name             => $DynamicFieldConfigs{Date}->{Label},
            Element          => 'DynamicField_' . $DynamicFieldConfigs{Date}->{Name},
            TimePeriodFormat => 'DateInputFormat',
            Block            => 'Time',
        },
    },
    {
        Name   => 'Dropdown DynamicField with PossibleValuesFilter (e.g. from ACL)',
        Config => {
            DynamicFieldConfig   => $DynamicFieldConfigs{Dropdown},
            PossibleValuesFilter => {
                1 => 'A',
            },
        },
        ExpectedResults => {
            Values => {
                1 => 'A',
            },
            Name               => $DynamicFieldConfigs{Dropdown}->{Label},
            Element            => 'DynamicField_' . $DynamicFieldConfigs{Dropdown}->{Name},
            TranslatableValues => $DynamicFieldConfigs{Dropdown}->{Config}->{TranslatableValues},
            Block              => 'MultiSelectField',
        },
    },
    {
        Name   => 'Multiselect DynamicField with PossibleValuesFilter (e.g. from ACL)',
        Config => {
            DynamicFieldConfig   => $DynamicFieldConfigs{Multiselect},
            PossibleValuesFilter => {
                1 => 'A',
            },
        },
        ExpectedResults => {
            Values => {
                1 => 'A',
            },
            Name               => $DynamicFieldConfigs{Multiselect}->{Label},
            Element            => 'DynamicField_' . $DynamicFieldConfigs{Multiselect}->{Name},
            TranslatableValues => $DynamicFieldConfigs{Multiselect}->{Config}->{TranslatableValues},
            Block              => 'MultiSelectField',
        },
    },
);

# execute tests
for my $Test (@Tests) {

    my $Result = $DFBackendObject->StatsFieldParameterBuild( %{ $Test->{Config} } );

    $Self->IsDeeply(
        $Result,
        $Test->{ExpectedResults},
        "$Test->{Name} | StatsSearchFieldParameterBuild()",
    );
}

# we don't need any cleanup

$Self->DoneTesting();
