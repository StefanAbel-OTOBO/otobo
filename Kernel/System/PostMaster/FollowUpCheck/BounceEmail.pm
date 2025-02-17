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

package Kernel::System::PostMaster::FollowUpCheck::BounceEmail;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
    'Kernel::System::Ticket',
    'Kernel::System::Ticket::Article',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{ParserObject} = $Param{ParserObject} || die "Got no ParserObject";

    # Get communication log object.
    $Self->{CommunicationLogObject} = $Param{CommunicationLogObject} || die "Got no CommunicationLogObject!";

    # Get Article backend object.
    $Self->{ArticleBackendObject} =
        $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForChannel( ChannelName => 'Email' );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->_AddCommunicationLog( Message => 'Searching for header X-OTOBO-Bounce.' );

    return if !$Param{GetParam}->{'X-OTOBO-Bounce'};

    my $BounceMessageID = $Param{GetParam}->{'X-OTOBO-Bounce-OriginalMessageID'};

    $Self->_AddCommunicationLog(
        Message => sprintf(
            'Searching for article with message id "%s".',
            $BounceMessageID,
        ),
    );

    # Look for the article that is associated with the BounceMessageID
    my %Article = $Self->{ArticleBackendObject}->ArticleGetByMessageID(
        MessageID => $BounceMessageID,
    );

    return if !%Article;

    $Self->_AddCommunicationLog(
        Message => sprintf(
            'Found corresponding article ID "%s".',
            $Article{ArticleID},
        ),
    );

    $Self->_SetArticleTransmissionSendError(
        %Param,
        ArticleID => $Article{ArticleID},
    );

    return $Article{TicketID};
}

sub _SetArticleTransmissionSendError {
    my ( $Self, %Param ) = @_;

    my $ArticleID            = $Param{ArticleID};
    my $ArticleObject        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $ArticleBackendObject = $ArticleObject->BackendForChannel(
        ChannelName => 'Email',
    );

    my $BounceError     = $Param{GetParam}->{'X-OTOBO-Bounce-ErrorMessage'};
    my $BounceMessageID = $Param{GetParam}->{'X-OTOBO-Bounce-OriginalMessageID'};

    my $CurrentStatus = $ArticleBackendObject->ArticleGetTransmissionError(
        ArticleID => $ArticleID,
    );

    if ($CurrentStatus) {

        my $Result = $ArticleBackendObject->ArticleUpdateTransmissionError(
            ArticleID => $ArticleID,
            Message   => $BounceError,
        );

        if ( !$Result ) {

            my $ErrorMessage = sprintf(
                'Error while updating transmission error for article "%s"!',
                $ArticleID,
            );

            $Self->_AddCommunicationLog(
                Message  => $ErrorMessage,
                Priority => 'Error',
            );
        }

        return;
    }

    my $Result = $ArticleBackendObject->ArticleCreateTransmissionError(
        ArticleID => $ArticleID,
        MessageID => $BounceMessageID,
        Message   => $BounceError,
    );

    if ( !$Result ) {

        my $ErrorMessage = sprintf(
            'Error while creating transmission error for article "%s"!',
            $ArticleID,
        );

        $Self->_AddCommunicationLog(
            Message  => $ErrorMessage,
            Priority => 'Error',
        );

        return;
    }

    return;
}

sub _AddCommunicationLog {
    my ( $Self, %Param ) = @_;

    $Self->{CommunicationLogObject}->ObjectLog(
        ObjectLogType => 'Message',
        Priority      => $Param{Priority} || 'Debug',
        Key           => ref($Self),
        Value         => $Param{Message},
    );

    return;
}

1;
