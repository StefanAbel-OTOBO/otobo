# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2025 Rother OSS GmbH, https://otobo.io/
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

package Kernel::System::SupportDataCollector::Plugin::OS::Distribution;

use strict;
use warnings;

use parent qw(Kernel::System::SupportDataCollector::PluginBase);

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::System::Environment',
);

sub GetDisplayPath {
    return Translatable('Operating System');
}

sub Run {
    my $Self = shift;

    my %OSInfo = $Kernel::OM->Get('Kernel::System::Environment')->OSInfoGet();

    # if OSname starts with Unknown, test was not successful
    if ( $OSInfo{OSName} =~ /\A Unknown /xms ) {
        $Self->AddResultProblem(
            Label   => Translatable('Distribution'),
            Value   => $OSInfo{OSName},
            Message => Translatable('Could not determine distribution.')
        );
    }
    else {
        $Self->AddResultInformation(
            Label => Translatable('Distribution'),
            Value => $OSInfo{OSName},
        );
    }

    return $Self->GetResults();
}

1;
