# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2024 Rother OSS GmbH, https://otobo.io/
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

use v5.24;
use strict;
use warnings;
use utf8;

# core modules
use Scalar::Util qw(weaken);

# CPAN modules
use Test2::V0;

# OTOBO modules
use Kernel::System::UnitTest::MockTime qw(FixedTimeSet);
use Kernel::System::UnitTest::RegisterOM;    # Set up $Kernel::OM
use Kernel::Output::HTML::Layout ();

# get needed objects
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

my $LayoutObject = Kernel::Output::HTML::Layout->new(
    UserID => 1,
    Lang   => 'de',
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my @Tests = (
    {
        Name => 'Simple data',
        Data => {
            Title => 'B&B'
        },
        Template => 'Test: [% Data.Title %]',
        Result   => 'Test: B&B',
    },
    {
        Name => 'Simple data with colons',
        Data => {
            'Title::Test' => 'B&B'
        },
        Template => 'Test: [% Data.item("Title::Test") %]',
        Result   => 'Test: B&B',
    },
    {
        Name => 'Simple data with underscore',
        Data => {
            Title_Sub => 'B&B'
        },
        Template => 'Test: [% Data.Title_Sub %]',
        Result   => 'Test: B&B',
    },
    {
        Name => 'Simple data, html quoting',
        Data => {
            Title => '<B&B>'
        },
        Template => 'Test: [% Data.Title | html %]',
        Result   => 'Test: &lt;B&amp;B&gt;',
    },
    {
        Name => 'Interpolate filter',
        Data => {
            Title    => 'B&B [% Data.TicketID %]',
            TicketID => '1234'
        },
        Template => 'Test: [% Data.Title | Interpolate %]',
        Result   => 'Test: B&B 1234',
    },
    {
        Name => 'Interpolate function',
        Data => {
            Title    => 'B&B [% Data.TicketID %]',
            TicketID => '1234'
        },
        Template => 'Test: [% Interpolate(Data.Title) %]',
        Result   => 'Test: B&B 1234',
    },
    {
        Name     => 'Config()',
        Template => '[% Config("Home") %]',
        Result   => $ConfigObject->Get('Home'),
    },
    {
        Name     => 'Env()',
        Template => '[% Env("UserLanguage") %]',
        Result   => 'de',
    },
    {
        Name => 'JSON filter',
        Data => {
            Title => "Some data with special characters ' \"."
        },
        Template => '[% Data.Title | JSON %]',
        Result   => '"Some data with special characters \' \\"."',
    },
    {
        Name => 'JSON function complex data',
        Data => {
            Array => ["Some data with special characters ' \"."],
        },
        Template => '[% JSON(Data.Array) %]',
        Result   => '["Some data with special characters \' \\"."]',
    },
    {
        Name     => 'Translate()',
        Template => '[% Translate("Yes") %]',
        Result   => 'Ja',
    },
    {
        Name     => 'Translate() with parameters',
        Template => '[% Translate("Customer %s added", "Testkunde") %]',
        Result   => "Kunde Testkunde hinzugef\x{00FC}gt",
    },
    {
        Name => 'Translate() filter with parameters',
        Data => {
            Text => 'Customer %s added',
        },
        Template => '[% Data.Text | Translate("Testkunde") %]',
        Result   => "Kunde Testkunde hinzugef\x{00FC}gt",
    },
    {
        Name => 'Localize() TimeLong',
        Data => {
            DateTime => '2000-01-01 00:00:00',
        },
        Template => '[% Data.DateTime | Localize("TimeLong") %]',
        Result   => '01.01.2000 00:00:00',
    },
    {
        Name => 'Localize() TimeShort',
        Data => {
            DateTime => '2000-01-01 00:00:00',
        },
        Template => '[% Data.DateTime | Localize("TimeShort") %]',
        Result   => '01.01.2000 00:00',
    },
    {
        Name => 'Localize() Date',
        Data => {
            DateTime => '2000-01-01 00:00:00',
        },
        Template => '[% Data.DateTime | Localize("Date") %]',
        Result   => '01.01.2000',
    },
    {
        Name => 'Localize() as function call',
        Data => {
            DateTime => '2000-01-01 00:00:00',
        },
        Template => '[% Localize(Data.DateTime, "Date") %]',
        Result   => '01.01.2000',
    },
    {
        Name => 'Blocks',
        Data => {
            Title => 'Template',
        },
        BlockData => [
            {
                Name => 'b1',
                Data => {
                    Title => 'b1',
                },
            },
            {
                Name => 'b11',
                Data => {
                    Title => 'b11',
                },
            },
            {
                Name => 'b11',
                Data => {
                    Title => 'b11',
                },
            },
            {
                Name => 'b12',
                Data => {
                    Title => 'b12',
                },
            },
            {
                Name => 'b1',
                Data => {
                    Title => 'b1',
                },
            },
            {
                Name => 'b2',
                Data => {
                    Title => 'b2',
                },
            },
            {
                Name => 'b21',
                Data => {
                    Title => 'b21',
                },
            },
            {
                Name => 'b2',
                Data => {
                    Title => 'b2',
                },
            },
        ],
        Template => '
[% RenderBlockStart("b1") %]
[% Data.Title %]
[% RenderBlockStart("b11") %]
[% Data.Title %]
[% RenderBlockEnd("b11") %]
[% RenderBlockStart("b12") %]
[% Data.Title %]
[% RenderBlockEnd("b12") %]
[% RenderBlockEnd("b1") %]
[% RenderBlockStart("b2") %]
[% Data.Title %]
[% RenderBlockStart("b21") %]
[% Data.Title %]
[% RenderBlockEnd("b21") %]
[% RenderBlockEnd("b2") %]
',
        Result => '
b1
b11
b11
b12
b1
b2
b21
b2
',
    },
    {
        Name => 'Unrendered Blocks',
        Data => {
            Title => 'Template',
        },
        BlockData => [
            {
                Name => 'b1',
                Data => {
                    Title => 'b1',
                },
            },
        ],
        Template => 'empty',
        Result   => 'empty',
    },
    {
        Name => 'Block from previous test',
        Data => {
            Title => 'Template',
        },
        BlockData => [],
        Template  => '
[% RenderBlockStart("b1") %]
[% Data.Title %]
[% RenderBlockEnd("b1") %]
',
        Result => '
b1
',
    },
    {
        Name => 'Block with single quotes',
        Data => {
            Title => 'Template',
        },
        BlockData => [
            {
                Name => 'b1',
                Data => {
                    Title => 'b1',
                },
            },
        ],
        Template => "
[% RenderBlockStart('b1') %]
[% Data.Title %]
[% RenderBlockEnd('b1') %]
",
        Result => '
b1
',
    },
    {
        Name     => 'JSOnDocumentComplete 1',
        Template => '
[% WRAPPER JSOnDocumentComplete -%]
console.log(11);
[% END -%]
[% WRAPPER JSOnDocumentComplete -%]
console.log(12);
[% END -%]',
        Result => '
',
    },
    {
        Name     => 'JSOnDocumentComplete 2 with AddJSOnDocumentComplete()',
        Template => '
[% WRAPPER JSOnDocumentComplete -%]
console.log(21);
[% END -%]
[% WRAPPER JSOnDocumentComplete -%]
console.log(22);
[% END -%]',
        AddJSOnDocumentComplete => "console.log(23);\n",
        Result                  => '
',
    },
    {
        Name     => 'JSOnDocumentCompleteInsert',
        Template => '
[% PROCESS "JSOnDocumentCompleteInsert" -%]',
        Result => '
console.log(11);

console.log(12);

console.log(23);

console.log(21);

console.log(22);
',
    },
    {
        Name     => 'JSOnDocumentCompleteInsert, no data',
        Template => '
[% PROCESS "JSOnDocumentCompleteInsert" -%]',
        Result => '
',
    },

    {
        # the accumulated config will be dumped in the test case 'JSDataInsert'
        Name     => 'JSData 1',
        Template => '
[% PROCESS JSData
    Key   = "Config.Test"
    Value = 123
%]
[% PROCESS JSData
    Key   = "Config.Test2"
    Value = [1, 2, { test => "test"}]
%]',
        Result => '

',
    },
    {
        # the accumulated config will be dumped in the test case 'JSDataInsert'
        Name      => 'JSData 2 with AddJSData()',
        Template  => '',
        AddJSData => {
            Key   => 'Perl.Code',
            Value => { Perl => 'Data' }
        },
        Result => '',
    },
    {
        # the accumulated config will be dumped in the test case 'JSDataInsert'
        Name      => 'JSData 3 with AddJSData()',
        Template  => '',
        AddJSData => {
            Key   => 'JS.String',
            Value => { String => '</script></script>' }
        },
        Result => '',
    },
    {
        # the accumulated config will be dumped in the test case 'JSDataInsert'
        Name      => 'JSData 4 with AddJSData()',
        Template  => '',
        AddJSData => {
            Key   => 'JS.String.CaseInsensitive',
            Value => { String => '</ScRiPt></ScRiPt>' },
        },
        Result => '',
    },
    {
        # the accumulated config will be dumped in the test case 'JSDataInsert'
        Name         => 'Boolean: integer 1',
        Template     => '',
        AddJSBoolean => {
            Key   => 'Bool1',
            Value => 1,
        },
        Result => '',
    },
    {
        # the accumulated config will be dumped in the test case 'JSDataInsert'
        Name         => 'Boolean number 0',
        Template     => '',
        AddJSBoolean => {
            Key   => 'Bool2',
            Value => 0,
        },
        Result => '',
    },
    {
        # the accumulated config will be dumped in the test case 'JSDataInsert'
        Name         => 'Boolean string q{1}',
        Template     => '',
        AddJSBoolean => {
            Key   => 'Bool3',
            Value => '1',
        },
        Result => '',
    },
    {
        # the accumulated config will be dumped in the test case 'JSDataInsert'
        Name         => 'Boolean string q{0]',
        Template     => '',
        AddJSBoolean => {
            Key   => 'Bool4',
            Value => '0',
        },
        Result => '',
    },
    {
        # the accumulated config will be dumped in the test case 'JSDataInsert'
        Name         => 'Boolean string q{0.0], true',
        Template     => '',
        AddJSBoolean => {
            Key   => 'Bool5',
            Value => '0.0',
        },
        Result => '',
    },
    {
        # the accumulated config will be dumped in the test case 'JSDataInsert'
        Name     => 'Process JSBoolean',
        Template => <<'END_TEMPLATE',
[% PROCESS JSBoolean
    Key   = "ProcessJSBoolean1"
    Value = 'true',
%]
[% PROCESS JSBoolean
    Key   = "ProcessJSBoolean2"
    Value = 'false',
%]
[% PROCESS JSBoolean
    Key   = "ProcessJSBoolean3"
    Value = 0,
%]
[% PROCESS JSBoolean
    Key   = "ProcessJSBoolean4"
    Value = 0.0,
%]
[% PROCESS JSBoolean
    Key   = "ProcessJSBoolean5"
    Value = "0",
%]
[% PROCESS JSBoolean
    Key   = "ProcessJSBoolean6"
    Value = "0.0",
%]
[% PROCESS JSBoolean
    Key   = "ProcessJSBoolean7"
    Value = 1 > 0,
%]
[% PROCESS JSBoolean
    Key   = "ProcessJSBoolean8"
    Value = 1 < 0,
%]
END_TEMPLATE
        Result => '







',
    },
    {
        # Dump the Core.Config data that was collected in the preceeding test cases
        Name     => 'JSDataInsert',
        Template => '
[% PROCESS "JSDataInsert" -%]',

        Result => '
Core.Config.AddConfig({"Bool1":true,"Bool2":false,"Bool3":true,"Bool4":false,"Bool5":true,"Config.Test":123,"Config.Test2":[1,2,{"test":"test"}],"JS.String":{"String":"<\/script><\/script>"},"JS.String.CaseInsensitive":{"String":"<\/ScRiPt><\/ScRiPt>"},"Perl.Code":{"Perl":"Data"},"ProcessJSBoolean1":true,"ProcessJSBoolean2":true,"ProcessJSBoolean3":false,"ProcessJSBoolean4":false,"ProcessJSBoolean5":false,"ProcessJSBoolean6":true,"ProcessJSBoolean7":true,"ProcessJSBoolean8":false});
',
    },
    {
        # no more config is dumped as the accumulator was emptied in the 'JSDataInsert' test case
        Name     => 'JSDataInsert, no data',
        Template => '[% PROCESS "JSDataInsert" -%]',
        Result   => '',
    },

    {
        Name     => 'Form without ChallengeToken',
        Template => '
<form action="#"></form>',
        Result => '
<form action="#"></form>',
    },
    {
        Name     => 'Form with ChallengeToken',
        Template => '
<form action="#"></form>',
        Result => '
<form action="#"><input type="hidden" name="ChallengeToken" value="TestToken"/></form>',
        Env => {
            UserChallengeToken => 'TestToken',
        },
    },
    {
        Name     => 'Form with SessionID (no cookie) and ChallengeToken',
        Template => '
<form action="#"></form>',
        Result => '
<form action="#"><input type="hidden" name="ChallengeToken" value="TestToken"/><input type="hidden" name="SID" value="123"/></form>',
        Env => {
            UserChallengeToken => 'TestToken',
            SessionID          => '123',
            SessionName        => 'SID',
            SessionIDCookie    => 0,
        },
    },
    {
        Name     => 'Form with SessionID (with cookie) and ChallengeToken',
        Template => '
<form action="#"></form>',
        Result => '
<form action="#"><input type="hidden" name="ChallengeToken" value="TestToken"/></form>',
        Env => {
            UserChallengeToken => 'TestToken',
            SessionID          => '123',
            SessionName        => 'Session',
            SessionIDCookie    => 1,
        },
    },
    {
        Name     => 'Link with SessionID (no cookie)',
        Template => '
<a href="index.pl?Action=Test">link</a>',
        Result => '
<a href="index.pl?Action=Test;SID=123">link</a>',
        Env => {
            UserChallengeToken => 'TestToken',
            SessionID          => '123',
            SessionName        => 'SID',
            SessionIDCookie    => 0,
        },
    },
    {
        Name     => 'Link with SessionID (with cookie)',
        Template => '
<a href="index.pl?Action=Test">link</a>',
        Result => '
<a href="index.pl?Action=Test">link</a>',
        Env => {
            UserChallengeToken => 'TestToken',
            SessionID          => '123',
            SessionName        => 'Session',
            SessionIDCookie    => 1,
        },
    },
    {
        Name     => 'Bulk replace (used in email notifications)',
        Template => <<'EOF',
[% Data.HTML
    .replace('<h1([^>]*)>', '<h1$1 style="...">')
    .replace('<p>', '<p style="...">')
%]
EOF
        Result => '<h1 class="test" style="...">Test</h1><p style="...">mytext</p><p style="...">mytext2</p>
',
        Data => {
            HTML => '<h1 class="test">Test</h1><p>mytext</p><p>mytext2</p>'
        },
    },
    {
        Name     => 'HumanReadableDataSize',
        Template => <<'EOF',
[% 123 | Localize( 'Filesize' ) %] [% Localize( 456 * 1024, 'Filesize' ) %] [% Localize( 789.5 * 1024 * 1024, 'Filesize' ) %]
EOF
        Result => '123 B 456 KB 789,5 MB
',
        Data => {},
    },
    {
        Name     => 'Replace',
        Template => <<'EOF',
[% "This is %s" | ReplacePlaceholders("<strong>bold text</strong>") %]
[% ReplacePlaceholders("This is %s", "<em>italic text</em>") %]
[% "This string has %s and %s placeholder" | ReplacePlaceholders("<strong>first</strong>", "<em>second</em>") %]
[% ReplacePlaceholders("This string has neither %s or %s text", "bold", "italic") %]
[% "This is an <unsafe> string with %s placeholder" | html | ReplacePlaceholders("<strong>safe</strong>") %]
EOF
        Result => 'This is <strong>bold text</strong>
This is <em>italic text</em>
This string has <strong>first</strong> and <em>second</em> placeholder
This string has neither bold or italic text
This is an &lt;unsafe&gt; string with <strong>safe</strong> placeholder
',
        Data => {},
    },
);

for my $Test (@Tests) {
    if ( $Test->{FixedTimeSet} ) {

        # Set current time to the provided timestamp.
        my $DateTimeObject = $Kernel::OM->Create(
            'Kernel::System::DateTime',
            ObjectParams => {
                String => $Test->{FixedTimeSet},
            },
        );

        FixedTimeSet($DateTimeObject);
    }

    # make sure EnvRef is populated every time
    delete $LayoutObject->{EnvRef};
    for my $Key ( sort keys %{ $Test->{Env} || {} } ) {
        $LayoutObject->{$Key} = $Test->{Env}->{$Key};
    }

    for my $Block ( @{ $Test->{BlockData} || [] } ) {
        $LayoutObject->Block( %{$Block} );
    }

    if ( $Test->{AddJSOnDocumentComplete} ) {
        $LayoutObject->AddJSOnDocumentComplete(
            Code => $Test->{AddJSOnDocumentComplete},
        );
    }

    if ( $Test->{AddJSData} ) {
        $LayoutObject->AddJSData(
            $Test->{AddJSData}->%*,
        );
    }

    if ( $Test->{AddJSBoolean} ) {
        $LayoutObject->AddJSBoolean(
            $Test->{AddJSBoolean}->%*,
        );
    }

    my $Result = $LayoutObject->Output(
        Template => $Test->{Template},
        Data     => $Test->{Data} // {},
    );

    is( $Result, $Test->{Result}, $Test->{Name} );

    # Reset time to the current timestamp.
    if ( $Test->{FixedTimeSet} ) {
        FixedTimeSet();
    }
}

# verify that the TemplateObject is correctly destroyed to make sure there
# are no ring references.
my $TemplateObject = $LayoutObject->{TemplateObject};

weaken($TemplateObject);

undef $LayoutObject;

ok( !defined $TemplateObject, 'TemplateObject must be correctly destroyed (no ring references)' );

done_testing;
