//
//  ViewController.m
//  XMPPDemo
//
//  Created by Cendy on 13-10-17.
//  Copyright (c) 2013年 com.Cendy. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *roster;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    if ([self connect]) {
        NSLog(@"connect success");
    } else {
        NSLog(@"connect error");
    }
    
    double delayInSeconds = 5.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSLog(@"zzz");
        if (!self.xmppStream.isDisconnected) {
            NSLog(@"xxx");
            [self sendMessage:@"hello victor" toUser:@"victor"];
        }
    });
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)connect
{
    BOOL success = NO;
    
    if (![self.xmppStream isConnected]) {
        NSString *userName = @"chee@chee.com";
        XMPPJID *jid = [XMPPJID jidWithString:userName];
        [self.xmppStream setMyJID:jid];
        [self.xmppStream setHostName:@"192.168.1.101"];
        NSError *error;
        if ([self.xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error]) {
            success = YES;
        }
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
        }
    }
    
    return success;
}

- (void)disconnect
{
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavalibable"];
    [self.xmppStream sendElement:presence];
    
    [self.xmppStream disconnect];
}

- (void)sendMessage:(NSString *)message toUser:(NSString *)user
{
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:message];
    
    NSXMLElement *mes = [NSXMLElement elementWithName:@"message"];
    [mes addAttributeWithName:@"type" stringValue:@"chat"];
    [mes addAttributeWithName:@"to" stringValue:[NSString stringWithFormat:@"%@@%@", user, self.xmppStream.myJID.domain]];
    [mes addAttributeWithName:@"from" stringValue:[self.xmppStream.myJID.user stringByAppendingString:self.xmppStream.myJID.domain]];
    [mes addChild:body];
    
    [self.xmppStream sendElement:mes];
    
    NSLog(@"send message : %@ to %@", message, user);
}

- (XMPPStream *)xmppStream
{
    if (!_xmppStream) {
        _xmppStream = [[XMPPStream alloc] init];
        [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _xmppStream;
}

- (void)queryRoster
{
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:roster"];
    NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
    XMPPJID *myJID = self.xmppStream.myJID;
    [iq addAttributeWithName:@"from" stringValue:myJID.description];
    [iq addAttributeWithName:@"to" stringValue:myJID.domain];
    [iq addAttributeWithName:@"id" stringValue:[self generateID]];
    [iq addAttributeWithName:@"type" stringValue:@"get"];
    [iq addChild:query];
    [self.xmppStream sendElement:iq];
}

- (NSString *)generateID
{
    return @"chee@chee.com";
}

#pragma mark - XMPPStreamDelegate
// connect
- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    NSString *password = @"shadowi";
    if ([sender authenticateWithPassword:password error:nil]) {
        NSLog(@"authenticate success");
    }
}

// authenticate
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"avalible"];
    [sender sendElement:presence];
    NSLog(@"presence is avalible");
}

// friends' presence
- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    NSString *presenceType = [presence type];
    NSString *presenceFromUser = [[presence from] user];
    if (![presenceFromUser isEqualToString:[[sender myJID] user]]) {
        if ([presenceType isEqualToString:@"available"]) {
            NSLog(@"presence available");
        }
        else if ([presenceType isEqualToString:@"away"]) {
            NSLog(@"presence away");
        }
        else if ([presenceType isEqualToString:@"do not disturb"]) {
            NSLog(@"presence do not disturb");
        }
        else if ([presenceType isEqualToString:@"unavailable"])
        {
            NSLog(@"presence unavailable");
        }
        else {
            NSLog(@"presence unkown");
        }
    }
}

// receive message
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    NSString *messageBody = [[message elementForName:@"body"] stringValue];
    NSLog(@"receive message : %@", messageBody);
}

// roster
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    if ([@"result" isEqualToString:iq.type]) {
        NSXMLElement *query = iq.childElement;
        if ([@"query" isEqualToString:query.name]) {
            NSArray *items = [query children];
            for (NSXMLElement *item in items) {
                NSString *jid = [item attributeStringValueForName:@"jid"];
                XMPPJID *xmppJID = [XMPPJID jidWithString:jid];
                [self.roster addObject:xmppJID];
            }
        }
    }
    
    return YES;
}

@end
