class Core extends SwatGame.SwatMutator
 implements HTTP.ClientOwner;

/**
 * Copyright (c) 2014 Sergei Khoroshilov <kh.sergei@gmail.com>
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import enum eClientError from HTTP.Client;

/**
 * MOTD package version
 * @type string
 */
const VERSION = "1.1.0-beta";

/**
 * Fixed tick rate (seconds)
 * @type float
 */
const DELTA = 0.5;

/**
 * Max message block length
 * @type int
 */
const MAX_BLOCK_LENGTH = 1024;

/**
 * Message block delimiter
 * @type string
 */
const BLOCK_DELIMITER = "\n\n";

/**
 * Header block delimiter
 * @type string
 */
const HEADER_DELIMITER = "\n";

/**
 * Message options delimiter
 * @type string
 */
const OPTION_DELIMITER = "\t";

/**
 * Message Block structure:
 *     Option1 $ OPTION_DELIMITER $ Option2 $ OPTION_DELIMITER $ Option3 $ HEADER_DELIMITER $ Line1\nLine2\n $ BLOCK_DELIMITER
 *
 * Example:
 *     60\t0\t*
 *     Welcome to the server!
 *     Please follow the rules and have fun.
 *
 *     65\t120\t*
 *     Visit us at example.com
 */

struct sMotdMessage
{
    /**
     * MOTD message
     * @type string
     */
    var string Message;

    /**
     * Initial message delay since level startup (in seconds) (Internal counter)
     * @type int
     */
    var int InitialDelay;

    /**
     * Time between repetitions (in seconds)
     * @type int
     */
    var int RepeatDelay;

    /**
     * Target's name (may aswell be a wildcard such as "*")
     * @type string
     */
    var string Target;

    /**
     * Time the message was last shown (Internal counter)
     * @type float
     */
    var float LastDisplayed;
};

/**
 * List of parsed motd messages
 * @type array<sMotdMessage>
 */
var protected array<sMotdMessage> Messages;

/**
 * HTTP client instance
 * @type class'HTTP.Client'
 */
var protected HTTP.Client Client;

/**
 * Indicate whether the mod is enabled
 * @type bool
 */
var config bool Enabled;

/**
 * List of MOTD sources
 * @type array<string>
 */
var config array<string> URL;

/**
 * Max number of messages that will be parsed from a http response
 * Set to 0 for infinity
 * @type int
 */
var config int MaxMessages;

/**
 * Check whether the mod is enabled
 * 
 * @return  void
 */
public function PreBeginPlay()
{
    Super.PreBeginPlay();

    if (Level.NetMode == NM_ListenServer || Level.NetMode == NM_DedicatedServer)
    {
        if (Level.Game != None && SwatGameInfo(Level.Game) != None)
        {
            if (self.Enabled && self.URL.Length > 0)
            {
                return;
            }
        }
    }
    self.Destroy();
}

/**
 * Aquire a http client instance and query the MOTD source
 * 
 * @return  void
 */
public function BeginPlay()
{
    local int i;

    Super.BeginPlay();

    log("MOTD (version " $ class'Core'.const.VERSION $ ") has been initialized");

    self.Client = Spawn(class'HTTP.Client');
    // Fetch MOTD sources
    for (i = 0; i < self.URL.Length; i++)
    {
        log("Sending a GET request to " $ self.URL[i]);
        self.Client.Send(Spawn(class'Message'), self.URL[i], 'GET', self, 1); 
    }
    
    // Repeat for the whole eternity
    self.SetTimer(class'Core'.const.DELTA, true);
}

/**
 * Go through the list of queued message and attempt display one by one
 */
event Timer()
{
    local int i;

    for (i = self.Messages.Length-1; i >= 0; i--)
    {
        // The message has not yet been displayed
        if (self.Messages[i].LastDisplayed < 0)
        {
            // but its time hasnt yet come 
            if (self.Messages[i].InitialDelay > Level.TimeSeconds)
            {
                continue;
            }
        }
        // This message has already been displayed, but its time hasnt come either
        else if (self.Messages[i].LastDisplayed > Level.TimeSeconds - self.Messages[i].RepeatDelay)
        {
            continue;
        }
        self.DisplayMessage(self.Messages[i].Message, self.Messages[i].Target);
        // This message was supposed to be displayed just once
        if (self.Messages[i].RepeatDelay == 0)
        {
            self.Messages.Remove(i, 1);
            continue;
        }
        self.Messages[i].LastDisplayed = Level.TimeSeconds;
    }
}

/**
 * Attempt to parse motd messages upon a successful response
 * 
 * @see HTTP.ClientOwner.OnRequestSuccess
 */
public function OnRequestSuccess(int StatusCode, string Response, string Hostname, int Port)
{
    local int i;
    local array<string> Blocks, Block, Options;

    if (StatusCode == 200)
    {
        Blocks = class'Utils.StringUtils'.static.Part(Response, class'Core'.const.BLOCK_DELIMITER);

        for (i = 0; i < Blocks.Length; i++)
        {
            if (Len(Blocks[i]) > class'Core'.const.MAX_BLOCK_LENGTH)
            {
                log(self $ ": " $ Left(Blocks[i], 20) $ " is too large to be parsed");
                continue;
            }
            // Split message header from the actual message
            Block = class'Utils.StringUtils'.static.Part(Blocks[i], class'Core'.const.HEADER_DELIMITER);

            if (Block.Length >= 2)
            {
                // Parse options
                Options = class'Utils.StringUtils'.static.Part(Block[0], class'Core'.const.OPTION_DELIMITER);
                // Get rid of the parsed header
                Block.Remove(0, 1);
                // Attempt to queue this message
                if (self.QueueMessage(class'Utils.ArrayUtils'.static.Join(Block, class'Core'.const.HEADER_DELIMITER), Options))
                {
                    continue;
                }
            }
            log(self $ ": failed to parse " $ Left(Blocks[i], 20));
        }
    }
    else
    {
        log(self $ ": MOTD source " $ Hostname $ " is not available (" $ StatusCode $ ")");
    }
}

/**
 * Log an error upon a failure
 * 
 * @see HTTP.ClientOwner.OnRequestFailure
 */
public function OnRequestFailure(eClientError ErrorCode, string ErrorMessage, string Hostname, int Port)
{
    log(self $ ": MOTD source " $ Hostname $ " is not available (" $ ErrorMessage $ ")");
}

/**
 * Attempt to queue a MOTD message
 * Return whether the operation was successful
 * 
 * @param   string Message
 *          MOTD message
 * @param   array<string> Options
 *          List of options
 * @return  bool
 */
protected function bool QueueMessage(string Message, array<string> Options)
{
    local sMotdMessage NewMessage;
    // Check for the message limit
    if (self.MaxMessages > 0 && self.Messages.Length >= self.MaxMessages)
    {
        log(self $ ": reached the message limit of " $ self.MaxMessages);
        return false;
    }
    Message = class'Utils.StringUtils'.static.Strip(Message);
    // The options array should at least contain 2 items (which is initial delay and repetition delay)
    if (Message != "" && Options.Length >= 2)
    {
        if (class'Utils.StringUtils'.static.IsDigit(Options[0]) && class'Utils.StringUtils'.static.IsDigit(Options[1]))
        {
            NewMessage.LastDisplayed = -1;
            NewMessage.InitialDelay = Max(0, int(Options[0]));
            NewMessage.RepeatDelay = Max(0, int(Options[1]));
            NewMessage.Message = Message;
            // Add an optional target
            if (Options.Length > 2)
            {
                NewMessage.Target = class'Utils.StringUtils'.static.Strip(Options[2]);
            }
            self.Messages[self.Messages.Length] = NewMessage;
            return true;
        }
    }
    return false;
}

/**
 * Display a targeted motd message
 * 
 * @param   string Message
 * @param   string Target
 * @return  void
 */
protected function DisplayMessage(string Message, string Target)
{
    local int i;
    local array<string> Lines;
    local string Name;
    local PlayerController PC;

    Lines = class'Utils.StringUtils'.static.Part(class'Utils.StringUtils'.static.NormNewline(Message), "\n");

    foreach DynamicActors(class'PlayerController', PC)
    {
        // Make name colourless
        Name = class'Utils.StringUtils'.static.Strip(
            class'Utils.StringUtils'.static.Filter(PC.PlayerReplicationInfo.PlayerName)
        );
        if (Target == "" || class'Utils.StringUtils'.static.Match(Name, Target))
        {
            // Display the message line by line
            for (i = 0; i < Lines.Length; i++)
            {
                class'Utils.LevelUtils'.static.TellPlayer(Level, Lines[i], PC);
            }
        }
    }
}

event Destroyed()
{
    if (self.Client != None)
    {
        self.Client.Destroy();
        self.Client = None;
    }

    log(self $ " is about to be destroyed");

    Super.Destroyed();
}

/* vim: set ft=java: */