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

package Kernel::System::Console::Command::Dev::Code::CPANUpdate;

use strict;
use warnings;

use File::Path();

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Main',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Update dependencies in Kernel/cpan-lib.');

    $Self->AddOption(
        Name        => 'mode',
        Description => "Update all dependencies (development), or only critical ones (stable).",
        Required    => 1,
        HasValue    => 1,
        Multiple    => 0,
        ValueRegex  => qr/^stable$/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home');
    my $Mode = $Self->GetOption('mode');

    my $CPANDir = "$Home/Kernel/cpan-lib";

    if ( $Mode eq 'stable' ) {

        MODULE_CONFIG:
        for my $ModuleConfig ( $Self->LoadModuleConfig() ) {
            next MODULE_CONFIG if !$ModuleConfig->{UpdateInStableMode};
            $Self->InstallModule(
                ModuleConfig => $ModuleConfig,
                TargetPath   => $CPANDir,
            );
        }

    }
    elsif ( $Mode eq 'development' ) {

        my $CPAN2Dir = "$Home/Kernel/cpan-lib2";

        # Delete Kernel/cpan-lib.
        if ( -d $CPAN2Dir ) {
            File::Path::remove_tree($CPAN2Dir) || die "Could not clean-up $CPAN2Dir: $!.";
        }
        File::Path::make_path($CPAN2Dir) || die "Could not create $CPAN2Dir: $!.";

        # Install modules.
        MODULE_CONFIG:
        for my $ModuleConfig ( $Self->LoadModuleConfig() ) {
            $Self->InstallModule(
                ModuleConfig => $ModuleConfig,
                TargetPath   => $CPAN2Dir,
            );
        }

        # Copy our own extension for Devel::REPL from previous cpan-lib folder.
        File::Path::make_path("$CPAN2Dir/Devel/REPL/Plugin");
        system("cp -r $CPANDir/Devel/REPL/Plugin/OTOBO.pm $CPAN2Dir/Devel/REPL/Plugin/OTOBO.pm");

        # Replace cpan-lib folder.
        File::Path::remove_tree($CPANDir) || die "Could not remove $CPANDir: $!.";
        rename $CPAN2Dir, $CPANDir || die "Could not replace $CPANDir: $!.";
    }

    # Clean-up unwanted files.
    File::Path::remove_tree("$CPANDir/Test/Selenium");
    system("find $CPANDir -name '*.pod' -exec rm -f {} +");
    system("find $CPANDir -name '*.pl*' -exec rm -f {} +");
    system("find $CPANDir -name '*.so' -exec rm -f {} +");
    system("find $CPANDir -name '*.exists' -exec rm -f {} +");

    # Fix unwanted 755 permissions.
    system("find $CPANDir -type f -exec chmod 640 {} +");

    my $ReadmeContent = <<EOF;
This directory contains bundled pure-perl CPAN modules that are used by the OTOBO source code.

Please note that this directory is auto-generated by the command `Dev::Code::CPANUpdate`.

License information of the bundled modules can be found in the
[COPYING-Third-Party](../../COPYING-Third-Party) file.
EOF

    $Kernel::OM->Get('Kernel::System::Main')->FileWrite(
        Location => "$CPANDir/README.md",
        Content  => \$ReadmeContent,
    );

    return $Self->ExitCodeOk();
}

sub InstallModule {
    my ( $Self, %Param ) = @_;

    my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home');

    my $ModuleConfig = $Param{ModuleConfig};
    my $TargetPath   = $Param{TargetPath};

    $Self->Print("Updating <yellow>$ModuleConfig->{Module}</yellow>...\n");

    my $TmpDir = "$Home/var/tmp/CPANUpdate";

    if ( -d $TmpDir ) {
        File::Path::remove_tree($TmpDir) || die "Could not clean-up $TmpDir: $!.";
    }
    File::Path::make_path($TmpDir) || die "Could not create $TmpDir: $!.";

    my $DownloadURL = `wget -q -O - https://fastapi.metacpan.org/v1/download_url/$ModuleConfig->{Module} | grep download_url | cut -d '"' -f4`;
    die "Error: Could not get DownloadURL." if !$DownloadURL;
    chomp $DownloadURL;

    system("cd $TmpDir; wget -q -O - $DownloadURL | tar -xz --strip 1");

    if ( $ModuleConfig->{BuildBLib} ) {
        system("cd $TmpDir; perl Makefile.PL; make; cp -r $TmpDir/blib/lib/* $TargetPath");
        return 1;
    }

    if ( -d "$TmpDir/lib" ) {
        system("cp -r $TmpDir/lib/* $TargetPath");
        return 1;
    }

    my @ModuleParts     = split( m{::}, $ModuleConfig->{Module} );
    my $LastModuleLevel = pop @ModuleParts;
    my $ModulePath      = join '/', @ModuleParts;
    if ( -f "$TmpDir/$LastModuleLevel.pm" ) {
        if ( !-d "$TargetPath/$ModulePath" ) {
            File::Path::make_path("$TargetPath/$ModulePath") || die "Could not create $TargetPath/$ModulePath: $!.";
        }
        system("cp -r $TmpDir/$LastModuleLevel.pm $TargetPath/$ModulePath");
        return 1;
    }

    die "Download and/or file extraction of $DownloadURL failed.";
}

sub LoadModuleConfig {
    return (
        {
            Module             => 'CPAN::Audit',
            UpdateInStableMode => 1,
        },
        {
            Module             => 'Mozilla::CA',
            UpdateInStableMode => 1,
        },
    );
}

1;
