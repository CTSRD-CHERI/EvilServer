/*-
 * Copyright (c) 2014 David Chisnall
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 */

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "WebPageWindow.h"

@implementation WebPageWindow
{
	// The object is self-owned (creating a retain cycle) until we decide that the window should go away.
	id retainCycle;
}
@synthesize view;
- (void)timeOut: (id)sender
{
	[[self window] performClose: self];
}
- (void)willClose: (NSNotification*)aNotification
{
	retainCycle = nil;
}
- (void)loadPage: (NSString*)page
{
	[[view mainFrame] loadHTMLString: page baseURL: nil];
	[[self window] makeKeyAndOrderFront: self];
	retainCycle = self;
	// When the window closes, get a notification so that we can clean up - we'll never re-open windows after they close.
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(willClose:)
												 name: NSWindowWillCloseNotification
											   object: [self window]];
	// Fire a timer after 10 seconds and close the window so that the screen doesn't get cluttered.
	[NSTimer scheduledTimerWithTimeInterval: 10
								target: self
							  selector: @selector(timeOut:)
							  userInfo: nil
							   repeats: NO];
}
@end
