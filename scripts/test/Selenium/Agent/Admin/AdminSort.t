# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2024 Rother OSS GmbH, https://otobo.de/
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

# core modules

# CPAN modules
use Test2::V0;

# OTOBO modules
use Kernel::System::UnitTest::RegisterOM;    # Set up $Kernel::OM
use Kernel::System::UnitTest::Selenium;

# get selenium object
my $Selenium = Kernel::System::UnitTest::Selenium->new( LogExecuteCommandActive => 1 );

$Selenium->RunTest(
    sub {

        # get needed objects
        my $Helper       = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

        # create and login test user
        my $Language      = 'hu';
        my $TestUserLogin = $Helper->TestUserCreate(
            Groups   => [ 'admin', 'users' ],
            Language => $Language,
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # get script alias
        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

        # navigate to appropriate screen in the test
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=Admin");

        my @NavigationChecks = (
            'Dinamikus mezők',
            'Dynamic Fields Screens',    # not yet translated to Hungarian
            'Folyamatkezelés',
            'Hozzáférés-vezérlési listák (ACL)',
            'Ticket Masks',              # not yet translated to Hungarian
            'Webszolgáltatások',
        );

        # Check if needed frontend module is registered in sysconfig.
        if ( $ConfigObject->Get('Frontend::Module')->{AdminGenericAgent} ) {
            unshift @NavigationChecks, 'Általános ügyintéző';
        }

        $Selenium->execute_script(
            "\$('.WidgetSimple:eq(7) ul')[0].scrollIntoView(true);",
        );

        # Check if items sort well.
        my $Count = 0;
        for my $Item (@NavigationChecks) {
            my $Navigation = $Selenium->execute_script(
                "return \$('.WidgetSimple:eq(7) ul li:eq($Count) a span.Title').text().trim()"
            );

            $Navigation =~ s/\n\s+/@/g;
            my @Navigation = split /\@/, $Navigation;

            is(
                $Navigation[0],
                $Item,
                "$Item - admin navigation item is sorted well",
            ) || die 'comparison failed';

            # Add item to favourite.
            $Selenium->execute_script(
                "\$('.WidgetSimple:eq(7) ul li:eq($Count) a span.AddAsFavourite').trigger('click')"
            );

            my $Favourite = $Selenium->execute_script(
                "return \$('.WidgetSimple:eq(7) ul li:eq($Count) a span.AddAsFavourite').attr('data-module')"
            );

            $Selenium->WaitFor(
                JavaScript =>
                    "return typeof(\$) === 'function' && \$('li[data-module=\"$Favourite\"]').hasClass('IsFavourite');"
            );

            ok(
                $Selenium->execute_script(
                    "return \$('li[data-module=\"$Favourite\"]').hasClass('IsFavourite');"
                ),
                "$Item - admin navigation item is added to favourite",
            );
        }
        continue {
            $Count++;
        }

        $Selenium->VerifiedRefresh();

        $Count = 0;
        for my $Item (@NavigationChecks) {

            # Check order in favoutite list.
            is(
                $Selenium->execute_script(
                    "return \$('.Favourites tr:eq($Count) a').text()"
                ),
                $Item,
                "$Item - admin navigation item is sort well",
            );

            # Check order in Admin navigation menu.
            $Count++;
            is(
                $Selenium->execute_script(
                    "return \$('#nav-Admin ul li:eq($Count) a').text()"
                ),
                $NavigationChecks[ $Count - 1 ],
                "$NavigationChecks[$Count-1] - admin navigation item is sort well",
            );
        }

        $Count = scalar @NavigationChecks;
        for my $Item (@NavigationChecks) {

            # Removes item from favourites.
            $Selenium->execute_script(
                "\$('.DataTable .RemoveFromFavourites:eq($Count)').trigger('click')"
            );

            $Selenium->WaitFor(
                JavaScript =>
                    "return typeof(\$) === 'function' && \$('.DataTable .RemoveFromFavourites').length == $Count;"
            );

            ok(
                $Selenium->execute_script(
                    "return \$('.DataTable .RemoveFromFavourites').length == $Count;"
                ),
                "$NavigationChecks[$Count-1] - admin navigation item is removed from favourite",
            );

            $Count--;
        }

        # Create new test user and set it's Admin favorites modules in preferences.
        my ( $SecondTestUserLogin, $SecondTestUserID ) = $Helper->TestUserCreate(
            Groups => [ 'admin', 'users' ],
        );

        my $Success = $Kernel::OM->Get('Kernel::System::User')->SetPreferences(
            UserID => $SecondTestUserID,
            Key    => 'AdminNavigationBarFavourites',
            Value  =>
                '["AdminUser","AdminSystemAddress","AdminAppointmentCalendarManage",
                "AdminCustomerUser","AdminPriority","AdminProcessManagement","AdminRole","AdminSystemConfiguration",
                "AdminLog","AdminAppointmentNotificationEvent","AdminTemplate","AdminEmail"]',
        );
        ok( $Success, "Set AdminNavigationBarFavourites for test user $SecondTestUserLogin." );

        # Login second test created user.
        $Selenium->Login(
            Type     => 'Agent',
            User     => $SecondTestUserLogin,
            Password => $SecondTestUserLogin,
        );

        # Verify that admin favorite modules are sorted in correct order in Admin nav bar.
        # See bug#13103 for more details.
        my @FavoriteAdminModules = (
            'Admin Notification',
            'Agents',
            'Appointment Notifications',
            'Calendars',
            'Customer Users',
            'Email Addresses',
            'Priorities',
            'Process Management',
            'Roles',
            'System Configuration',
            'System Log',
            'Templates'
        );

        $Count = 0;
        for my $Item (@FavoriteAdminModules) {

            # Check order in Admin navigation menu.
            $Count++;
            is(
                $Selenium->execute_script(
                    "return \$('#nav-Admin ul li:eq($Count) a').text()"
                ),
                $FavoriteAdminModules[ $Count - 1 ],
                "$FavoriteAdminModules[$Count-1] - admin navigation item is correctly sorted.",
            );
        }
    }
);

done_testing;
