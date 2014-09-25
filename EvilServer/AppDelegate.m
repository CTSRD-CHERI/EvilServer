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

#import "AppDelegate.h"
#import "WebPageWindow.h"
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate
{
	NSMutableArray *array;
	NSFileHandle *listeningSocket;
}
- (void)handlePage: (NSNotification*)aNotification
{
	NSData *page = [[aNotification userInfo] objectForKey: NSFileHandleNotificationDataItem];
	NSString *htmlString = [[NSString alloc] initWithData: page encoding: NSUTF8StringEncoding];
	WebPageWindow *window = [[WebPageWindow alloc] initWithWindowNibName: @"WebPageWindow"];
	[window window];
	[window loadPage: htmlString];
}
- (void)accept: (NSNotification*)aNotification
{
	NSFileHandle *sock = [[aNotification userInfo] objectForKey: NSFileHandleNotificationFileHandleItem];
	[sock readToEndOfFileInBackgroundAndNotify];
	[listeningSocket acceptConnectionInBackgroundAndNotify];
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Set up the socket
	int fd = socket(PF_INET, SOCK_STREAM, 0);
	struct sockaddr_in serv_addr;
	bzero(&serv_addr, sizeof(serv_addr));
	serv_addr.sin_family = AF_INET;
	serv_addr.sin_addr.s_addr = INADDR_ANY;
	serv_addr.sin_port = htons(1234);
	int err = bind(fd, (struct sockaddr *)&serv_addr, sizeof(serv_addr));
	if (err != 0)
	{
		NSLog(@"Failed to bind");
		exit(EXIT_FAILURE);
	}
	if ((err = listen(fd, 5)) != 0)
	{
		NSLog(@"Failed to listen");
		exit(EXIT_FAILURE);
	}
	listeningSocket = [[NSFileHandle alloc] initWithFileDescriptor: fd closeOnDealloc: YES];
	[listeningSocket acceptConnectionInBackgroundAndNotify];

	// Make sure that we get the notifications
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver: self
		   selector: @selector(accept:)
			   name: NSFileHandleConnectionAcceptedNotification
			 object: listeningSocket];
	[nc addObserver: self
		   selector: @selector(handlePage:)
			   name: NSFileHandleReadToEndOfFileCompletionNotification
			 object: nil];


	array = [NSMutableArray new];
}

@end
