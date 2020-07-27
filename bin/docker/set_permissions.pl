#!/usr/bin/env perl
# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2020 Rother OSS GmbH, https://otobo.de/
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
use warnings;
use utf8;

# core modules
use File::Find qw();
use File::stat qw();
use Getopt::Long qw();
use Data::Dumper;

# CPAN modules
use Path::Class qw(dir);

# OTOBO modules

my ( $DryRun ); # file scoped for convenience

sub PrintUsage {
    print <<'END_USAGE';

Set OTOBO file permissions.

Usage:
 otobo.SetPermissions.pl [--dir=<DIR>] [--otobo-user=<OTOBO_USER>] [--otobo-group=<OTOBO_GROUP>] [--admin-group=<ADMIN_GROUP>] [--skip-article-dir] [--skip-regex="REGEX"] [--dry-run] dir

Options:
 [--dir=<DIR>]                 - directory where permissions are to be set, defaults to '.'.
 [--otobo-user=<OTOBO_USER>]   - OTOBO user, defaults to 'otobo'.
 [--otobo-group=<OTOBO_GROUP>] - OTOBO group, defaults to 'otobo'
 [--admin-group=<ADMIN_GROUP>] - Admin group, defaults to 'root'.
 [--skip-article-dir]          - Skip var/article as it might take too long on some systems.
 [--skip-regex="REGEX"]        - Add another skip regex like "^/var/my/directory". Paths start with / but are relative to the OTOBO directory. --skip-regex can be specified multiple times.
 [--dry-run]                   - Only report, don't change.
 [--help]                      - Display help for this command.

Help:
Using this script without any options it will try to detect the correct user and group settings needed for your setup.

    perl bin/docker/set_permissions.pl

END_USAGE

    return;
}

# Files/directories that should be ignored and not recursed into.
my @IgnoreFiles = (
    qr{^/\.git}smx,
    qr{^/\.tidyall}smx,
    qr{^/\.settings}smx,
    qr{^/\.ssh}smx,
    qr{^/\.gpg}smx,
    qr{^/\.gnupg}smx,
);

# Files to be marked as executable.
my @ExecutableFiles = (
    qr{\.(?:pl|psgi|sh)$}smx,
    qr{^/var/git/hooks/(?:pre|post)-receive$}smx,
);

# Special files that must not be written by webserver user.
my @ProtectedFiles = (
    qr{^/\.fetchmailrc$}smx,
    qr{^/\.procmailrc$}smx,
);

my $ExitStatus = 0;

sub Run {
    my $OtoboDirectory = '.';       # default: the current working dir
    my $OtoboUser      = 'otobo';   # default: otobo
    my $OtoboGroup     = 'otobo';   # the user otobo is in the group otobo
    my $AdminGroup     = 'root';    # default: root
    my ( $Help, $SkipArticleDir, @SkipRegex  );

    Getopt::Long::GetOptions(
        'help'             => \$Help,
        'dir=s'            => \$OtoboDirectory,
        'otobo-user=s'     => \$OtoboUser,
        'otobo-group=s'    => \$OtoboGroup,
        'admin-group=s'    => \$AdminGroup,
        'dry-run'          => \$DryRun,
        'skip-article-dir' => \$SkipArticleDir,
        'skip-regex=s'     => \@SkipRegex,
    );

    if ( $Help ) {
        PrintUsage();

        exit 0;
    }

    if ( $> != 0 ) {    # $EFFECTIVE_USER_ID
        print STDERR "ERROR: Please run this script as superuser (root).\n";

        exit 1;
    }

    # check params

    if ( !$OtoboDirectory ) {
        say STDERR "ERROR: --dir is missing.";

        exit 1;
    }

    if ( ! -d $OtoboDirectory ) {
        say STDERR "ERROR: $OtoboDirectory isn't a directory";

        exit 1;
    }

    my $OtoboUserID = getpwnam $OtoboUser;
    if ( !$OtoboUser || !defined $OtoboUserID ) {
        say STDERR "ERROR: --otobo-user is missing or invalid.";

        exit 1;
    }

    my $OtoboGroupID = getgrnam $OtoboGroup;
    if ( !$OtoboGroup || !defined $OtoboGroupID ) {
        say STDERR "ERROR: --otobo-group is missing or invalid.";

        exit 1;
    }

    my $AdminGroupID = getgrnam $AdminGroup;
    if ( !$AdminGroup || !defined $AdminGroupID ) {
        say STDERR "ERROR: --admin-group is invalid.";

        exit 1;
    }

    # Continue with the absolute path, mainly for consistency.
    $OtoboDirectory = dir($OtoboDirectory)->absolute->stringify;

    if ( defined $SkipArticleDir ) {
        push @IgnoreFiles, qr{^/var/article}smx;
    }

    for my $Regex (@SkipRegex) {
        push @IgnoreFiles, qr{$Regex}smx;
    }

    say "Setting permissions on $OtoboDirectory";
    File::Find::find(
        {
            wanted   => sub {
                    SetPermissions( $OtoboDirectory, $OtoboUserID, $OtoboGroupID, $AdminGroupID );
                },
            no_chdir => 1,
            follow   => 1,
        },
        $OtoboDirectory,
    );

    exit $ExitStatus;
}

sub SetPermissions {
    my ( $OtoboDirectory, $OtoboUserID, $OtoboGroupID, $AdminGroupID ) = @_;

    # First get a canonical full filename
    my $File = $File::Find::fullname;

    # If the link is a dangling symbolic link, then fullname will be set to undef.
    return if !defined $File;

    # Make sure it is inside the OTOBO directory to avoid following symlinks outside
    my $OtoboDirectoryLength = length $OtoboDirectory;
    if ( substr( $File, 0, $OtoboDirectoryLength ) ne $OtoboDirectory ) {
        $File::Find::prune = 1;    # don't descend into subdirectories

        return;
    }

    # Now get a canonical relative filename under the OTOBO directory
    my $RelativeFile = substr( $File, $OtoboDirectoryLength ) || '/';

    for my $IgnoreRegex (@IgnoreFiles) {
        if ( $RelativeFile =~ $IgnoreRegex ) {
            $File::Find::prune = 1;    # don't descend into subdirectories
            say "Skipping $RelativeFile";

            return;
        }
    }

    # Ok, get target permissions for file
    SetFilePermissions( $File, $RelativeFile, $OtoboUserID, $OtoboGroupID, $AdminGroupID );

    return;
}

sub SetFilePermissions {
    my ( $File, $RelativeFile, $OtoboUserID, $OtoboGroupID, $AdminGroupID ) = @_;

    ## no critic (ProhibitLeadingZeros)
    # Writable by default, owner OTOBO and group webserver.
    my ( $TargetPermission, $TargetUserID, $TargetGroupID ) = ( 0660, $OtoboUserID, $OtoboGroupID );
    if ( -d $File ) {

        # SETGID for all directories so that both OTOBO and the web server can write to the files.
        # Other users should be able to read and cd to the directories.
        $TargetPermission = 02775;
    }
    else {
        # Executable bit for script files.
        EXEXUTABLE_REGEX:
        for my $ExecutableRegex (@ExecutableFiles) {
            if ( $RelativeFile =~ $ExecutableRegex ) {
                $TargetPermission = 0770;

                last EXEXUTABLE_REGEX;
            }
        }

        # Some files are protected and must not be written by webserver. Set admin group.
        PROTECTED_REGEX:
        for my $ProtectedRegex (@ProtectedFiles) {
            if ( $RelativeFile =~ $ProtectedRegex ) {
                $TargetPermission = -d $File ? 0750 : 0640;
                $TargetGroupID    = $AdminGroupID;

                last PROTECTED_REGEX;
            }
        }
    }

    # Special treatment for toplevel folder: this must be readonly,
    #   otherwise procmail will refuse to read .procmailrc (see bug#9391).
    if ( $RelativeFile eq '/' ) {
        $TargetPermission = 0755;
    }

    # There seem to be cases when stat does not work on a dangling link, skip in this case.
    my $Stat = File::stat::stat($File) || return;
    if ( ( $Stat->mode() & 07777 ) != $TargetPermission ) {
        if ( defined $DryRun ) {
            print sprintf(
                "$RelativeFile permissions %o -> %o\n",
                $Stat->mode() & 07777,
                $TargetPermission
            );
        }
        elsif ( !chmod( $TargetPermission, $File ) ) {
            print STDERR sprintf(
                "ERROR: could not change $RelativeFile permissions %o -> %o: $!\n",
                $Stat->mode() & 07777,
                $TargetPermission
            );
            $ExitStatus = 1;
        }
    }
    if ( ( $Stat->uid() != $TargetUserID ) || ( $Stat->gid() != $TargetGroupID ) ) {
        if ( defined $DryRun ) {
            print sprintf(
                "$RelativeFile ownership %s:%s -> %s:%s\n",
                $Stat->uid(),
                $Stat->gid(),
                $TargetUserID,
                $TargetGroupID
            );
        }
        elsif ( !chown( $TargetUserID, $TargetGroupID, $File ) ) {
            print STDERR sprintf(
                "ERROR: could not change $RelativeFile ownership %s:%s -> %s:%s: $!\n",
                $Stat->uid(),
                $Stat->gid(),
                $TargetUserID,
                $TargetGroupID
            );
            $ExitStatus = 1;
        }
    }

    return;
    ## use critic
}

Run();
