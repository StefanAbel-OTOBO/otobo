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

# get HTMLUtils object
my $HTMLUtilsObject = $Kernel::OM->Get('Kernel::System::HTMLUtils');

# DocumentCleanup tests
my @Tests = (
    {
        Input  => '<p class="MsoNormal">Sehr geehrte Damen und Herren,<o:p></o:p></p>',
        Result => 'Sehr geehrte Damen und Herren,<o:p></o:p><br/>',
        Name   => 'DocumentCleanup - MSHTML'
    },
    {
        Input  => "<p\n class=\"MsoNormal\">Sehr geehrte Damen und Herren,<o:p></o:p></p>",
        Result => 'Sehr geehrte Damen und Herren,<o:p></o:p><br/>',
        Name   => 'DocumentCleanup - MSHTML'
    },
    {
        Input =>
            "<p\n class=\"MsoNormal\">Sehr geehrte Damen und Herren,<o:p></o:p></p>\n<p\nclass=\"MsoNormal\"><o:p>&nbsp;</o:p></p>",
        Result => "Sehr geehrte Damen und Herren,<o:p></o:p><br/>\n<o:p>&nbsp;</o:p><br/>",
        Name   => 'DocumentCleanup - MSHTML'
    },
    {
        Input  => "<p class='MsoNormal'>Sehr geehrte Damen und Herren,<o:p></o:p></p>",
        Result => 'Sehr geehrte Damen und Herren,<o:p></o:p><br/>',
        Name   => 'DocumentCleanup - MSHTML'
    },
    {
        Input  => "<p\n class='MsoNormal'>Sehr geehrte Damen und Herren,<o:p></o:p></p>",
        Result => 'Sehr geehrte Damen und Herren,<o:p></o:p><br/>',
        Name   => 'DocumentCleanup - MSHTML'
    },
    {
        Input =>
            "<p\n class='MsoNormal'>Sehr geehrte Damen und Herren,<o:p></o:p></p>\n<p\nclass='MsoNormal'><o:p>&nbsp;</o:p></p>",
        Result => "Sehr geehrte Damen und Herren,<o:p></o:p><br/>\n<o:p>&nbsp;</o:p><br/>",
        Name   => 'DocumentCleanup - MSHTML'
    },
    {
        Input =>
            "<p class=MsoNormal>Sehr geehrte Damen und Herren,<o:p></o:p></p>Some Other Text... ",
        Result => 'Sehr geehrte Damen und Herren,<o:p></o:p><br/>Some Other Text... ',
        Name   => 'DocumentCleanup - MSHTML'
    },
    {
        Input  => "<p\n class=MsoNormal>Sehr geehrte Damen und Herren,<o:p></o:p></p>",
        Result => 'Sehr geehrte Damen und Herren,<o:p></o:p><br/>',
        Name   => 'DocumentCleanup - MSHTML'
    },
    {
        Input =>
            "<p\n class=MsoNormal>Sehr geehrte Damen und Herren,<o:p></o:p></p>\n<p\nclass='MsoNormal'><o:p>&nbsp;</o:p></p>",
        Result => "Sehr geehrte Damen und Herren,<o:p></o:p><br/>\n<o:p>&nbsp;</o:p><br/>",
        Name   => 'DocumentCleanup - MSHTML'
    },
    {
        Input =>
            "<div\n class=MsoNormal>Sehr geehrte Damen und Herren,<o:div></o:div></div>\n<div\nclass='MsoNormal'><o:div>&nbsp;</o:div></div>",
        Result => "Sehr geehrte Damen und Herren,<o:div></o:div><br/>\n<o:div>&nbsp;</o:div><br/>",
        Name   => 'DocumentCleanup - MSHTML'
    },
    {
        Input =>
            "<div\r class=MsoNormal>Sehr geehrte Damen und Herren,<o:div></o:div></div>\n<div class='MsoNormal' type=\"cite\"><o:div>&nbsp;</o:div></div>",
        Result => "Sehr geehrte Damen und Herren,<o:div></o:div><br/>\n<o:div>&nbsp;</o:div><br/>",
        Name   => 'DocumentCleanup - MSHTML'
    },
    {
        Input  => 'Some Tex<b>t</b>',
        Result => 'Some Tex<b>t</b>',
        Name   => 'DocumentCleanup - blockquote'
    },
    {
        Input  => '<blockquote>Some Tex<b>t</b></blockquote>',
        Result =>
            '<div  style="border:none;border-left:solid blue 1.5pt;padding:0cm 0cm 0cm 4.0pt">Some Tex<b>t</b></div>',
        Name => 'DocumentCleanup - blockquote'
    },
    {
        Input  => '<blockquote>Some Tex<b>t</b><blockquote>test</blockquote> </blockquote>',
        Result =>
            '<div  style="border:none;border-left:solid blue 1.5pt;padding:0cm 0cm 0cm 4.0pt">Some Tex<b>t</b><div  style="border:none;border-left:solid blue 1.5pt;padding:0cm 0cm 0cm 4.0pt">test</div> </div>',
        Name => 'DocumentCleanup - blockquote'
    },
    {
        Input =>
            '<head><base href=3D"file:///C:\Users\dol\AppData\Local\Temp\SnipFile-%7b102B7C0B-D396-440B-9DD6-DD3342805533%7d.HTML"></head>',
        Result => '<head></head>',
        Name   => 'DocumentCleanup - base tag',
    },
    {
        Input =>
            '<head><baSe href=3D"file:///C:\Users\dol\AppData\Local\Temp\SnipFile-%7b102B7C0B-D396-440B-9DD6-DD3342805533%7d.HTML"></head>',
        Result => '<head></head>',
        Name   => 'DocumentCleanup - baSe tag',
    },
    {
        Input =>
            '<HEAD><TITLE>Aufzeichnung</TITLE>
<META content=3D"text/html; charset=3Dus-ascii" http-equiv=3DContent-Type><=
BASE=20
href=3D"file:///C:/Users/goi/AppData/Local/Temp/SnipFile-%7B77CE7BE6-0C04-4=
CED-898D-4ECC17BCA028%7D.HTML">
</HEAD>',
        Result => '<HEAD><TITLE>Aufzeichnung</TITLE>
<META content=3D"text/html; charset=3Dus-ascii" http-equiv=3DContent-Type><=
BASE=20
href=3D"file:///C:/Users/goi/AppData/Local/Temp/SnipFile-%7B77CE7BE6-0C04-4=
CED-898D-4ECC17BCA028%7D.HTML">
</HEAD>',
        Name => 'DocumentCleanup - BASE tag',
    },
);

for my $Test (@Tests) {
    my $HTML = $HTMLUtilsObject->DocumentCleanup(
        String => $Test->{Input},
    );
    $Self->Is(
        $HTML,
        $Test->{Result},
        $Test->{Name},
    );
}

$Self->DoneTesting();
