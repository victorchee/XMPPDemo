//
//  ViewController.h
//  XMPPDemo
//
//  Created by Cendy on 13-10-17.
//  Copyright (c) 2013年 com.Cendy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XMPPFramework.h"

@interface ViewController : UIViewController <XMPPStreamDelegate>

@property (nonatomic, strong) XMPPStream *xmppStream;

- (BOOL)connect;
- (void)disconnect;

@end
