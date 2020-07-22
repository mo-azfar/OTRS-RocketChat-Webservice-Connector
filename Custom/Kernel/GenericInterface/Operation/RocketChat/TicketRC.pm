# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --
package Kernel::GenericInterface::Operation::RocketChat::TicketRC;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use base qw(
    Kernel::GenericInterface::Operation::Common
    Kernel::GenericInterface::Operation::RocketChat::Common
);

use utf8;
use Encode qw(decode encode);
use Digest::MD5 qw(md5_hex);
use Date::Parse;

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Needed (qw( DebuggerObject WebserviceID )) {
        if ( !$Param{$Needed} ) {

            return {
                Success      => 0,
                ErrorMessage => "Got no $Needed!"
            };
        }

        $Self->{$Needed} = $Param{$Needed};
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    if (
        !$Param{Data}->{UserLogin}
        && !$Param{Data}->{CustomerUserLogin}
        && !$Param{Data}->{SessionID}
        )
    {
        return $Self->ReturnError(
            ErrorCode    => 'RocketChat.MissingParameter',
            ErrorMessage => "RocketChat: UserLogin, CustomerUserLogin or SessionID is required!",
        );
    }

    if ( $Param{Data}->{UserLogin} || $Param{Data}->{CustomerUserLogin} ) {

        if ( !$Param{Data}->{Password} )
        {
            return $Self->ReturnError(
                ErrorCode    => 'RocketChat.MissingParameter',
                ErrorMessage => "RocketChat: Password or SessionID is required!",
            );
        }
    }
	
    my ( $UserID, $UserType ) = $Self->Auth(
        %Param,
    );

    if ( !$UserID ) {
        return $Self->ReturnError(
            ErrorCode    => 'RocketChat.AuthFail',
            ErrorMessage => "RocketChat: User could not be authenticated!",
        );
    }
    
    my $RCOTRSToken = $Param{Data}->{token};
    
    #verify token
    my $TokenID = $Self->ValidateToken(
        Token => $RCOTRSToken,
    );
    
    if ( !$TokenID ) {
        return $Self->ReturnError(
            ErrorCode    => 'RocketChat.NoToken',
            ErrorMessage => "RocketChat: Token Not Defined or Same in OTRS Configuration!",
        );
    }
    
    #verify not rc bot
    my $bot_id = $Param{Data}->{bot};
    if ( $bot_id ne 0 ) #TODO: try to convert to info instead of error
    {
        return $Self->ReturnError(
            ErrorCode    => 'RocketChat.ResponseNotValid',
            ErrorMessage => "This is response from bot. Only user allowed",
        );
    }
    
    my $RCUserLogin    = $Param{Data}->{user_name};
    
    #verify rc user
    my $AgentID = $Self->ValidateRCUser(
        User => $RCUserLogin,
    );
    
    if ( !$AgentID ) {
        return $Self->ReturnError (
            ErrorCode    => 'RocketChat.NoUser',
            ErrorMessage => "RocketChat: No RCUser $RCUserLogin Defined in OTRS!",
        );
    }
        
    my $text = $Param{Data}->{text};
    my $siteUrl      = $Param{Data}->{siteUrl};
    
    #text format should be command/ticketnumber e.g: get/123
    my @getCommand = split '/', $text;
    my $command = $getCommand[0];
    my $tn = $getCommand[1];
    my $note = $getCommand[2];
   
    #verify command
    my $cmd = $Self->ValidateCommand(
        Command => $command,
    );
    
    if ( !$cmd )
    {
        return {
            Success => 1,
            Data    => {
                'text'      => "Command <$command> invalid. Type help for info",  
            },
        };
    }
    
    if ( $cmd eq "help")
    {
        return {
            Success => 1,
            Data    => {
                'text'      => "Format <command>/<ticketnumber> . Available command as below",
                "attachments"=> [
                                {
                                "title"=> "mine",
                                "text"=> "To get all the ticket assigned under you",
                                },
                                {
                                "title"=> "get/<ticketnumber>",
                                "text"=> "To get the details of specific ticket",
                                },
                                {
                                "title"=> "addnote/<ticketnumber>",
                                "text"=> "To add a note to the specific ticket",
                                }
                                ]
            },
        };
    }
    
    if ( $cmd eq "mine")
    {

        #check owner ticket
        my $TicketOwnerText = $Self->MyOwner(
        AgentID => $AgentID,
        );
    
        #check responsible ticket
        my $TicketResponsibleText = $Self->MyResponsible(
        AgentID => $AgentID,
        );
        
        return 
        {
            Success => 1,
            Data    => 
            {
                'text'      => "My Ticket", 
                "attachments"=> [
                                {
                                "title"=> "Ticket Owner",
                                #"title_link"=> "$Ticket{TicketURL}",
                                "text"=> "$TicketOwnerText",
                                #"image_url" => "$ImageURL"
                                #"color"=> "#764FA5"
                                },
                                {
                                "title"=> "Ticket Responsible",
                                #"title_link"=> "$Ticket{TicketURL}",
                                "text"=> "$TicketResponsibleText",
                                #"image_url" => "$ImageURL"
                                #"color"=> "#764FA5"
                                }
                                ]
            },
        };
    
    }
	
    my $TicketID = $TicketObject->TicketIDLookup( TicketNumber => $tn, );
    my $ImageURL = "http://icons.iconarchive.com/icons/artua/star-wars/256/Clone-Trooper-icon.png";
    
    if ( $cmd eq "get")
    {
        if ($TicketID) 
        {
            
            my %getTicket = $Self->GetTicket(
                TicketID => $TicketID,
                UserID   => $AgentID,
            ); 
        
            return 
            {
                Success => 1,
                Data    => 
                {
                    "attachments"=> [
                                    {
                                    "title"=> "OTRS#$getTicket{TicketNumber}",
                                    "title_link"=> "$getTicket{TicketURL}",
                                    "text"=> "$getTicket{GetText}",
                                    "image_url" => "$ImageURL"
                                    #"color"=> "#764FA5"
                                    }
                                    ]
                },
            };
        }
        else
        {
            return 
            {
                Success => 1,
                Data    => 
                {
                    "attachments"=> [
                                    {
                                    "title"=> "Error: Requested Ticket#$tn Not Found",
                                    "image_url" => "$ImageURL"
                                    }
                                    ]
                },
            };
        }
    
    }
      
    if ( $cmd eq "addnote" )
    {
        if ( $TicketID && $note ne "" )
        {
            my $AddNote = $Self->AddNote(
                TicketID => $TicketID,
                AgentID => $AgentID,
                Body => $note,
            );
            
            return 
            {
                Success => 1,
                Data    => 
                {
                    #'text'  => $AddNote,
                    "attachments"=> [
                                    {
                                    "title"=> "$AddNote",
                                    "image_url" => "$ImageURL"
                                    }
                                    ]
                },
            };
            
        }
        else
        {
            return 
            {
                Success => 1,
                Data    => 
                {
                    "attachments"=> [
                                    {
                                    "title"=> "Error: Requested Ticket#$tn Not Found or Note is Empty",
                                    "image_url" => "$ImageURL"
                                    }
                                    ]
                },
            };
        }
        
    }
    
    
}

1;
