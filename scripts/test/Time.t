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

use strict;
use warnings;
use utf8;

# Set up the test driver $Self when we are running as a standalone script.
use Kernel::System::UnitTest::RegisterDriver;

use vars (qw($Self));

# get needed objects
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

# set time zone for data storage and calendars
$ConfigObject->Set(
    Key   => 'OTOBOTimeZone',
    Value => 'Europe/Berlin',
);
$ConfigObject->Set(
    Key   => 'TimeZone::Calendar1',
    Value => 'Europe/Berlin',
);
$ConfigObject->Set(
    Key   => 'TimeZone::Calendar9',
    Value => 'Atlantic/Cape_Verde',
);

$ConfigObject->Set(
    Key   => 'TimeZone::Calendar8',
    Value => 'Europe/Berlin',
);

$ConfigObject->Set(
    Key   => 'TimeZone::Calendar7',
    Value => 'Europe/Berlin',
);

my $TimeObject = $Kernel::OM->Get('Kernel::System::Time');

# TimeStamp2SystemTime tests
# See the command: date -d"2005-10-20T10:00:00Z" +%s
my @TimeStamp2SystemTimeTests = (
    {
        Description    => 'Zulu time',
        String         => '2005-10-20T10:00:00Z',
        ExpectedResult => 1129802400,
    },
    {
        Description    => 'UTC with offset +00:00',
        String         => '2005-10-20T10:00:00+00:00',
        ExpectedResult => 1129802400,
    },
    {
        Description    => 'UTC with offset -00:00',
        String         => '2005-10-20T10:00:00-00:00',
        ExpectedResult => 1129802400,
    },
    {
        Description    => 'UTC with offset -00',
        String         => '2005-10-20T10:00:00-00',
        ExpectedResult => 1129802400,
    },
    {
        Description    => 'UTC with offset +0',
        String         => '2005-10-20T10:00:00+0',
        ExpectedResult => 1129802400,
    },
    {
        Description    => 'Europe/Belgrade in funny format',
        String         => '20-10-2005 10:00:00',
        ExpectedResult => 1129795200,
    },
    {
        Description    => 'Europe/Belgrade in ISO-8601, with space as separator',
        String         => '2005-10-20 10:00:00',
        ExpectedResult => 1129795200,
    },
    {
        Description    => 'Europe/Belgrade in ISO-8601, with T as separator',
        String         => '2005-10-20T10:00:00',
        ExpectedResult => 1129795200,
    },
    {
        Description    => 'Nepal',
        String         => '2020-08-25T10:00:00+5:45',
        ExpectedResult => 1598328900,
    },
    {
        Description    => 'Newfoundland',
        String         => '2020-08-25T00:45:00-3:30',
        ExpectedResult => 1598328900,
    },
);

for my $Test (@TimeStamp2SystemTimeTests) {
    my $SystemTime  = $TimeObject->TimeStamp2SystemTime( String => $Test->{String} );
    my $Description = 'TimeStamp2SystemTime(): ' . ( $Test->{Description} // 'system time matches' );

    $Self->Is( $SystemTime, $Test->{ExpectedResult}, $Description );
}

#
# SystemTime2Date and Date2SystemTime tests
#
my $SystemTime = $TimeObject->TimeStamp2SystemTime( String => '2005-10-20 10:00:00' );

my ( $Sec, $Min, $Hour, $Day, $Month, $Year ) =
    $TimeObject->SystemTime2Date( SystemTime => $SystemTime );
$Self->Is(
    "$Year-$Month-$Day $Hour:$Min:$Sec",
    '2005-10-20 10:00:00',
    'Date string generated by SystemTime2Date() must match expected one.',
);

my $SystemTimeFromDateParts = $TimeObject->Date2SystemTime(
    Year   => 2005,
    Month  => 10,
    Day    => 20,
    Hour   => 10,
    Minute => 0,
    Second => 0,
);
$Self->Is(
    $SystemTimeFromDateParts,
    $SystemTime,
    'System time generated by Date2SystemTime() must match expected one.',
);

#
# WorkingTime tests
#
my @WorkingTimeTests = (
    {
        StartDateString => '2005-10-20 10:00:00',
        StopDateString  => '2005-10-21 10:00:00',
        ExpectedResult  => 13,
    },
    {
        StartDateString => '2005-10-20 10:00:00',
        StopDateString  => '2005-10-24 10:00:00',
        ExpectedResult  => 26,
    },
    {
        StartDateString => '2005-10-20 10:00:00',
        StopDateString  => '2005-10-27 10:00:00',
        ExpectedResult  => 65,
    },
    {
        StartDateString => '2005-10-20 10:00:00',
        StopDateString  => '2005-11-03 10:00:00',
        ExpectedResult  => 130,
    },
    {
        StartDateString => '2005-12-21 10:00:00',
        StopDateString  => '2005-12-31 10:00:00',
        ExpectedResult  => 89,
    },
    {
        StartDateString => '2003-12-21 10:00:00',
        StopDateString  => '2003-12-31 10:00:00',
        ExpectedResult  => 52,
    },
    {
        StartDateString => '2005-10-23 10:00:00',
        StopDateString  => '2005-10-24 10:00:00',
        ExpectedResult  => 2,
    },
    {
        StartDateString => '2005-10-23 10:00:00',
        StopDateString  => '2005-10-25 13:00:00',
        ExpectedResult  => 18,
    },
    {
        StartDateString => '2005-10-23 10:00:00',
        StopDateString  => '2005-10-30 13:00:00',
        ExpectedResult  => 65,
    },
    {
        StartDateString => '2005-10-24 11:44:12',
        StopDateString  => '2005-10-24 16:13:31',
        ExpectedResult  => 4.48861111111111,        # 16:13:31 - 11:44:12 => 4:29:19 = 4.4886...
    },
    {
        StartDateString => '2006-12-05 22:57:34',
        StopDateString  => '2006-12-06 10:25:34',
        ExpectedResult  => 2.42611111111111,        # 1 10:25:23 - 22:57:35 => 2:25:34 = 2,426...
    },
    {
        StartDateString => '2006-12-06 07:50:00',
        StopDateString  => '2006-12-07 08:54:00',
        ExpectedResult  => 13.9,
    },
    {
        StartDateString => '2007-03-12 11:56:01',
        StopDateString  => '2007-03-12 13:56:01',
        ExpectedResult  => 2,
    },
    {
        StartDateString => '2010-01-28 22:00:02',
        StopDateString  => '2010-01-28 22:01:02',
        ExpectedResult  => 0,
    },
);

for my $Test (@WorkingTimeTests) {

    my $StartSystemTime = $TimeObject->TimeStamp2SystemTime( String => $Test->{StartDateString} );
    my $StopSystemTime  = $TimeObject->TimeStamp2SystemTime( String => $Test->{StopDateString} );

    my $WorkingTime = $TimeObject->WorkingTime(
        StartTime => $StartSystemTime,
        StopTime  => $StopSystemTime,
    );

    # Convert working time from seconds to to hours.
    $WorkingTime /= 60 * 60;

    $Self->Is(
        $WorkingTime,
        $Test->{ExpectedResult},
        "Hours of WorkingTime() between $Test->{StartDateString} and $Test->{StopDateString} must match expected ones.",
    );
}

#
# DestinationTime tests
#
my @DestinationTime = (
    {
        Name            => 'Test 1',
        StartTime       => '2006-11-12 10:15:00',
        StartTimeSystem => '',
        Diff            => 60 * 60 * 4,
        EndTime         => '2006-11-13 12:00:00',
        EndTimeSystem   => '',
    },
    {
        Name            => 'Test 2',
        StartTime       => '2006-11-13 10:15:00',
        StartTimeSystem => '',
        Diff            => 60 * 60 * 4,
        EndTime         => '2006-11-13 14:15:00',
        EndTimeSystem   => '',
    },
    {
        Name            => 'Test 3',
        StartTime       => '2006-11-13 10:15:00',
        StartTimeSystem => '',
        Diff            => 60 * 60 * 11,
        EndTime         => '2006-11-14 08:15:00',
        EndTimeSystem   => '',
    },
    {
        Name            => 'Test 4',
        StartTime       => '2006-12-31 10:15:00',
        StartTimeSystem => '',
        Diff            => 60 * 60 * 11,
        EndTime         => '2007-01-02 19:00:00',
        EndTimeSystem   => '',
    },
    {
        Name            => 'Test 5',
        StartTime       => '2006-12-29 10:15:00',
        StartTimeSystem => '',
        Diff            => 60 * 60 * 11,
        EndTime         => '2007-01-02 08:15:00',
        EndTimeSystem   => '',
    },
    {
        Name            => 'Test 6',
        StartTime       => '2006-12-30 10:45:00',
        StartTimeSystem => '',
        Diff            => 60 * 60 * 11,
        EndTime         => '2007-01-02 19:00:00',
        EndTimeSystem   => '',
    },
    {
        Name            => 'Test 7',
        StartTime       => '2006-12-06 07:50:00',
        StartTimeSystem => '',
        Diff            => 50040,
        EndTime         => '2006-12-07 08:54:00',
        EndTimeSystem   => '',
    },
    {
        Name            => 'Test 8',
        StartTime       => '2007-01-16 20:15:00',
        StartTimeSystem => '',
        Diff            => 60 * 60 * 1.25,
        EndTime         => '2007-01-17 08:30:00',
        EndTimeSystem   => '',
    },
    {
        Name            => 'Test 9',
        StartTime       => '2007-03-14 21:21:02',
        StartTimeSystem => '',
        Diff            => 60 * 60,
        EndTime         => '2007-03-15 09:00:00',
        EndTimeSystem   => '',
    },
    {
        Name            => 'Test 10',
        StartTime       => '2007-03-12 11:56:01',
        StartTimeSystem => '',
        Diff            => 60 * 60 * 2,
        EndTime         => '2007-03-12 13:56:01',
        EndTimeSystem   => '',
    },
    {
        Name            => 'Test 11',
        StartTime       => '2007-03-15 17:21:27',
        StartTimeSystem => '',
        Diff            => 60 * 60 * 3,
        EndTime         => '2007-03-15 20:21:27',
        EndTimeSystem   => '',
    },

    # Summertime test - switch back to winter time (without + 60 minutes)
    {
        Name            => 'Test summertime -> wintertime (prepare without +60 min)',
        StartTime       => '2007-10-19 18:12:23',
        StartTimeSystem => 1192810343,
        Diff            => 60 * 60 * 5.5,
        EndTime         => '2007-10-22 10:42:23',
        EndTimeSystem   => 1193042543,
    },

    # Summertime test - switch back to winter time (+ 60 minutes)
    {
        Name            => 'Test summertime -> wintertime (+60 min)',
        StartTime       => '2007-10-26 18:12:23',
        StartTimeSystem => '1193415143',
        Diff            => 60 * 60 * 5.5,
        EndTime         => '2007-10-29 10:42:23',
        EndTimeSystem   => 1193650943,
    },

    # Summertime test - switch back to winter time (without + 60 minutes)
    {
        Name            => 'Test summertime -> wintertime (prepare without +60 min)',
        StartTime       => '2007-10-19 18:12:23',
        StartTimeSystem => 1192810343,
        Diff            => 60 * 60 * 18.5,
        EndTime         => '2007-10-23 10:42:23',
        EndTimeSystem   => 1193128943,
    },

    # Summertime test - switch back to winter time (+ 60 minutes)
    {
        Name            => 'Test summertime -> wintertime (+60 min)',
        StartTime       => '2007-10-26 18:12:23',
        StartTimeSystem => '1193415143',
        Diff            => 60 * 60 * 18.5,
        EndTime         => '2007-10-30 10:42:23',
        EndTimeSystem   => 1193737343,
    },

    # Wintertime test - switch to summer time (without - 60 minutes)
    {
        Name            => 'Test wintertime -> summertime (prepare without -60 min)',
        StartTime       => '2007-03-16 18:12:23',
        StartTimeSystem => '1174065143',
        Diff            => 60 * 60 * 5.5,
        EndTime         => '2007-03-19 10:42:23',
        EndTimeSystem   => 1174297343,
    },

    # Wintertime test - switch to summer time (- 60 minutes)
    {
        Name            => 'Test wintertime -> summertime (-60 min)',
        StartTime       => '2007-03-23 18:12:23',
        StartTimeSystem => 1174669943,
        Diff            => 60 * 60 * 5.5,
        EndTime         => '2007-03-26 10:42:23',
        EndTimeSystem   => 1174898543,
    },

    # Wintertime test - switch to summer time (without - 60 minutes)
    {
        Name            => 'Test wintertime -> summertime (prepare without -60 min)',
        StartTime       => '2007-03-16 18:12:23',
        StartTimeSystem => 1174065143,
        Diff            => 60 * 60 * 18.5,
        EndTime         => '2007-03-20 10:42:23',
        EndTimeSystem   => 1174383743,
    },

    # Wintertime test - switch to summer time (- 60 minutes)
    {
        Name            => 'Test wintertime -> summertime (-60 min)',
        StartTime       => '2007-03-23 18:12:23',
        StartTimeSystem => 1174669943,
        Diff            => 60 * 60 * 18.5,
        EndTime         => '2007-03-27 10:42:23',
        EndTimeSystem   => 1174984943,
    },

    # Behavior tests
    {
        Name            => 'Test weekend',
        StartTime       => '2013-03-16 10:00:00',    # Saturday
        StartTimeSystem => '',
        Diff            => 60 * 1,
        EndTime         => '2013-03-18 08:01:00',    # Monday
        EndTimeSystem   => '',
    },
    {
        Name            => 'Test weekend -1',
        StartTime       => '2013-03-16 10:00:00',    # Saturday
        Calendar        => 9,
        StartTimeSystem => '',
        Diff            => 60 * 1,
        EndTime         => '2013-03-18 10:01:00',    # Monday
        EndTimeSystem   => '',
    },
    {
        Name            => 'Test weekend +1',
        StartTime       => '2013-03-16 10:00:00',    # Saturday
        Calendar        => 8,
        StartTimeSystem => '',
        Diff            => 60 * 1,
        EndTime         => '2013-03-18 08:01:00',    # Monday
        EndTimeSystem   => '',
    },
    {
        Name            => 'Test weekend',
        StartTime       => '2013-03-16 10:00:00',    # Saturday
        StartTimeSystem => '',
        Diff            => 60 * 60 * 1,
        EndTime         => '2013-03-18 09:00:00',    # Monday
        EndTimeSystem   => '',
    },
    {
        Name            => 'Test weekend',
        StartTime       => '2013-03-16 10:00:00',    # Saturday
        StartTimeSystem => '',
        Diff            => 60 * 60 * 13,
        EndTime         => '2013-03-18 21:00:00',    # Monday
        EndTimeSystem   => '',
    },
    {
        Name            => 'Test weekend',
        StartTime       => '2013-03-16 10:00:00',    # Saturday
        StartTimeSystem => '',
        Diff            => 60 * 60 * 14 + 60 * 1,
        EndTime         => '2013-03-19 09:01:00',    # Monday
        EndTimeSystem   => '',
    },
);

for my $Test (@DestinationTime) {

    # get system time
    my $SystemTimeDestination = $TimeObject->TimeStamp2SystemTime( String => $Test->{StartTime} );

    # check system time
    if ( $Test->{StartTimeSystem} ) {
        $Self->Is(
            $SystemTimeDestination,
            $Test->{StartTimeSystem},
            "TimeStamp2SystemTime() - $Test->{Name}",
        );
    }

    # get system destination time based on calendar settings
    my $DestinationTime = $TimeObject->DestinationTime(
        StartTime => $SystemTimeDestination,
        Time      => $Test->{Diff},
        Calendar  => $Test->{Calendar},
    );

    # check system destination time
    if ( $Test->{EndTimeSystem} ) {
        $Self->Is(
            $DestinationTime,
            $Test->{EndTimeSystem},
            "DestinationTime() - $Test->{Name}",
        );
    }

    # check time stamp destination time
    my ( $Sec, $Min, $Hour, $Day, $Month, $Year ) =
        $TimeObject->SystemTime2Date( SystemTime => $DestinationTime );
    $Self->Is(
        "$Year-$Month-$Day $Hour:$Min:$Sec",
        $Test->{EndTime},
        "DestinationTime() - $Test->{Name}",
    );
}

#
# Random roundtrip tests for working and destination time
#
my @WorkingTimeDestinationTimeRoundtrip = (
    {
        Name       => 'Test 1',
        BaseDate   => '2013-12-26 15:15:00',
        DaysBefore => 8,
        DaysAfter  => 12,
        Runs       => 80,
        Calendar   => '',
        MaxDiff    => 4 * 24 * 60 * 60,
    },
    {
        Name       => 'Test 2',
        BaseDate   => '2013-10-24 04:41:17',
        DaysBefore => 3,
        DaysAfter  => 12,
        Runs       => 40,
        Calendar   => '',
        MaxDiff    => 3 * 24 * 60 * 60,
    },
    {
        Name       => 'Test 3',
        BaseDate   => '2013-03-01 10:11:12',
        DaysBefore => 5,
        DaysAfter  => 180,
        Runs       => 40,
        Calendar   => 7,                       # 24/7
        MaxDiff    => 0,
    },
);

# modify calendar 7 -- 24/7
my $WorkingHoursFull = [ '0' .. '23' ];
$ConfigObject->Set(
    Key   => 'TimeWorkingHours::Calendar7',
    Value => {
        map { $_ => $WorkingHoursFull } qw( Mon Tue Wed Thu Fri Sat Sun ),
    },
);

for my $Test (@WorkingTimeDestinationTimeRoundtrip) {
    my $BaseDate   = $Test->{BaseDate};
    my $BaseTime   = $TimeObject->TimeStamp2SystemTime( String => $BaseDate );
    my $DaysBefore = $Test->{DaysBefore};
    my $DaysAfter  = $Test->{DaysAfter};
    for my $Run ( 1 .. 40 ) {

        # Use random start/stop dates around base date
        my $StartTime = $BaseTime - int( $DaysBefore * 24 * 60 * 60 );
        my $StartDate = $TimeObject->SystemTime2TimeStamp( SystemTime => $StartTime );
        my $StopTime  = $BaseTime + int( $DaysAfter * 24 * 60 * 60 );
        my $StopDate  = $TimeObject->SystemTime2TimeStamp( SystemTime => $StopTime );

        my $WorkingTime = $TimeObject->WorkingTime(
            StartTime => $StartTime,
            StopTime  => $StopTime,
            Calendar  => $Test->{Calendar},
        );
        my $DestinationTime = $TimeObject->DestinationTime(
            StartTime => $StartTime,
            Time      => $WorkingTime,
            Calendar  => $Test->{Calendar},
        );
        my $WorkingTime2 = $TimeObject->WorkingTime(    # re-check
            StartTime => $StartTime,
            StopTime  => $DestinationTime,
            Calendar  => $Test->{Calendar},
        );
        my $DestinationDate = $TimeObject->SystemTime2TimeStamp( SystemTime => $DestinationTime );
        my $WH              = int( $WorkingTime / 3600 );
        my $WM              = int( ( $WorkingTime - $WH * 3600 ) / 60 );
        my $WS              = $WorkingTime - $WH * 3600 - $WM * 60;
        my $WT              = sprintf( "%u:%02u:%02u", $WH, $WM, $WS );

        my $Ok = $DestinationTime >= $StopTime - $Test->{MaxDiff}    # within MaxDiff of StopDate...
            && $DestinationTime <= $StopTime                         # ...but not later
            && $WorkingTime == $WorkingTime2;

        $Self->Is(
            $Ok,
            1,
            "WorkingTime/DestinationTime roundtrip $Test->{Name}.$Run -- $StartDate .. $DestinationDate <= $StopDate ($WT)",
        );

        if ( !$Ok ) {
            print "\tStart: $StartTime / $StartDate\n";
            print "\tStop:  $StopTime / $StopDate\n";
            print "\tDest:  $DestinationTime / $DestinationDate\n";
            print "\tWork:  $WT = $WorkingTime"
                . ( $WorkingTime != $WorkingTime2 ? " --> $WorkingTime2" : "" ) . "\n";
        }
    }
}

#
# Vacation tests
#
my $Vacation = '';

# 2005-01-01
$Vacation = $TimeObject->VacationCheck(
    Year  => '2005',
    Month => '1',
    Day   => '1',
);

$Self->Is(
    $Vacation || 0,
    "New Year's Day",
    'Vacation - 2005-01-01',
);

# 2005-01-01
$Vacation = $TimeObject->VacationCheck(
    Year  => '2005',
    Month => '01',
    Day   => '01',
);

$Self->Is(
    $Vacation || 0,
    "New Year's Day",
    'Vacation - 2005-01-01',
);

# 2005-12-31
$Vacation = $TimeObject->VacationCheck(
    Year  => '2005',
    Month => '12',
    Day   => '31',
);

$Self->Is(
    $Vacation || 0,
    'New Year\'s Eve',
    'Vacation - 2005-12-31',
);

# 2005-02-14
$Vacation = $TimeObject->VacationCheck(
    Year  => 2005,
    Month => '02',
    Day   => '14',
);

$Self->Is(
    $Vacation || 'no vacation day',
    'no vacation day',
    'Vacation - 2005-02-14',
);

# modify calendar 1
my $TimeVacationDays1        = $ConfigObject->Get('TimeVacationDays::Calendar1');
my $TimeVacationDaysOneTime1 = $ConfigObject->Get('TimeVacationDaysOneTime::Calendar1');

# 2005-01-01
$Vacation = $TimeObject->VacationCheck(
    Year     => 2005,
    Month    => 1,
    Day      => 1,
    Calendar => 1,
);

$Self->Is(
    $Vacation || 0,
    'New Year\'s Day',
    'Vacation - 2005-01-01 (Calendar1)',
);

# 2005-01-01
$Vacation = $TimeObject->VacationCheck(
    Year     => 2005,
    Month    => '01',
    Day      => '01',
    Calendar => 1,
);

$Self->Is(
    $Vacation || 0,
    'New Year\'s Day',
    'Vacation - 2005-01-01 (Calendar1)',
);

# remove vacation days
$TimeVacationDays1->{1}->{1} = undef;
$TimeVacationDaysOneTime1->{2004}->{1}->{1} = undef;

# 2005-01-01
$Vacation = $TimeObject->VacationCheck(
    Year     => 2005,
    Month    => 1,
    Day      => 1,
    Calendar => 1,
);

$Self->Is(
    $Vacation || 'no vacation day',
    'no vacation day',
    'Vacation - 2005-01-01 (Calendar1)',
);

# 2005-01-01
$Vacation = $TimeObject->VacationCheck(
    Year     => 2005,
    Month    => '01',
    Day      => '01',
    Calendar => 1,
);

$Self->Is(
    $Vacation || 'no vacation day',
    'no vacation day',
    'Vacation - 2005-01-01 (Calendar1)',
);

# 2004-01-01
$Vacation = $TimeObject->VacationCheck(
    Year     => 2004,
    Month    => 1,
    Day      => 1,
    Calendar => 1,
);

$Self->Is(
    $Vacation || 'no vacation day',
    'no vacation day',
    'Vacation - 2004-01-01 (Calendar1)',
);

# 2004-01-01
$Vacation = $TimeObject->VacationCheck(
    Year     => 2004,
    Month    => '01',
    Day      => '01',
    Calendar => 1,
);

$Self->Is(
    $Vacation || 'no vacation day',
    'no vacation day',
    'Vacation - 2004-01-01 (Calendar1)',
);

# 2005-02-14
$Vacation = $TimeObject->VacationCheck(
    Year     => 2005,
    Month    => '02',
    Day      => '14',
    Calendar => 1,
);

$Self->Is(
    $Vacation || 'no vacation day',
    'no vacation day',
    'Vacation - 2005-02-14 (Calendar1)',
);

#
# UTC tests
#

# set time zone for data storage
$ConfigObject->Set(
    Key   => 'OTOBOTimeZone',
    Value => 'UTC',
);
my @Tests = (
    {
        Name       => 'Zero Hour',
        TimeStamp  => '1970-01-01 00:00:00',
        SystemTime => 0,
    },
    {
        Name       => '+ Second',
        TimeStamp  => '1970-01-01 00:00:01',
        SystemTime => 1,
    },
    {
        Name       => '+ Hour',
        TimeStamp  => '1970-01-01 01:00:00',
        SystemTime => 3600,
    },
    {
        Name       => '- Second',
        TimeStamp  => '1969-12-31 23:59:59',
        SystemTime => -1,
    },
    {
        Name       => '- Hour',
        TimeStamp  => '1969-12-31 23:00:00',
        SystemTime => -3600,
    },
);

# Discard time object because of changed time zone
$Kernel::OM->ObjectsDiscard(
    Objects => [ 'Kernel::System::Time', ],
);
$TimeObject = $Kernel::OM->Get('Kernel::System::Time');

# the following tests imply a conversion to 'Date' in the middle, so tests for 'Date' are not
# needed
for my $Test (@Tests) {

    my $SystemTime = $TimeObject->TimeStamp2SystemTime( String => $Test->{TimeStamp} );
    $Self->Is(
        $SystemTime,
        $Test->{SystemTime},
        " $Test->{Name} TimeStamp2SystemTime()",
    );
    my $TimeStamp = $TimeObject->SystemTime2TimeStamp(
        SystemTime => $Test->{SystemTime},
    );
    $Self->Is(
        $TimeStamp,
        $Test->{TimeStamp},
        " $Test->{Name} SystemTime2TimeStamp()",
    );
}

$Self->DoneTesting();
